require 'socket'

module Moneta
  # Moneta server to be used together with Moneta::Adapters::Client
  # @api public
  class Server
    TIMEOUT = 1
    MAXSIZE = 0x100000

    # @api private
    class Connection
      def initialize(io, store)
        @io = io
        @store = store
        @fiber = Fiber.new { run }
      end

      def resume(result = nil)
        @fiber.resume result
      end

      private

      # The return value of this function will be sent to the reactor.
      #
      # @return [:closed,Exception]
      def run
        catch :closed do
          loop { write_dispatch(read_msg) }
        end
        :closed
      rescue => ex
        ex
      ensure
        @io.close unless @io.closed?
      end

      def dispatch(method, args)
        case method
        when :key?, :load, :delete, :increment, :create, :features
          @store.public_send(method, *args)
        when :store, :clear
          @store.public_send(method, *args)
          nil
        when :each_key
          yield_each(@store.each_key)
          nil
        end
      rescue => ex
        ex
      end

      def write_dispatch(msg)
        method, *args = msg
        result = dispatch(method, args)
        write(result)
      end

      def read_msg
        size = read(4).unpack('N').first
        throw :closed, 'Message too big' if size > MAXSIZE
        Marshal.load(read(size))
      end

      def read(len)
        buffer = ''
        loop do
          begin
            case received = @io.recv_nonblock(len)
            when '', nil
              throw :closed, 'Closed during read'
            else
              buffer << received
              len -= received.bytesize
            end
          rescue IO::WaitReadable, IO::WaitWritable
            yield_to_reactor(:read)
          rescue Errno::ECONNRESET
            throw :closed, 'Closed during read'
          rescue IOError => ex
            if ex.message =~ /closed stream/
              throw :closed, 'Closed during read'
            else
              raise
            end
          end
          break if len == 0
        end
        buffer
      end

      def write(obj)
        buffer = pack(obj)
        until buffer.empty?
          begin
            len = sendmsg(buffer)
            buffer = buffer.byteslice(len...buffer.length)
          rescue IO::WaitWritable, Errno::EINTR
            yield_to_reactor(:write)
          end
        end
        nil
      end

      # Detect support for socket#sendmsg_nonblock
      Socket.new(Socket::AF_INET, Socket::SOCK_STREAM).tap do |socket|
        begin
          socket.sendmsg_nonblock('probe')
        rescue Errno::EPIPE, Errno::ENOTCONN
          def sendmsg(msg)
            @io.sendmsg_nonblock(msg)
          end
        rescue NotImplementedError
          def sendmsg(msg)
            @io.write_nonblock(msg)
          end
        end
      end

      def yield_to_reactor(mode = :read)
        if Fiber.yield(mode) == :close
          throw :closed, 'Closed by reactor'
        end
      end

      def pack(obj)
        s = Marshal.dump(obj)
        [s.bytesize].pack('N') << s
      end

      def yield_each(enumerator)
        received_break = false
        loop do
          case msg = read_msg
          when %w{NEXT}
            # This will raise a StopIteration at the end of the enumeration,
            # which will exit the loop.
            write(enumerator.next)
          when %w{BREAK}
            # This is received when the client wants to stop the enumeration.
            received_break = true
            break
          else
            # Otherwise, the client is attempting to call another method within
            # an `each` block.
            write_dispatch(msg)
          end
        end
      ensure
        # This tells the client to stop enumerating
        write(StopIteration.new("Server initiated stop")) unless received_break
      end
    end

    # @param [Hash] options
    # @option options [Integer] :port (9000) TCP port
    # @option options [String] :socket Alternative Unix socket file name
    def initialize(store, options = {})
      @store = store
      @server = start(options)
      @ios = [@server]
      @reads = @ios.dup
      @writes = []
      @connections = {}
      @running = false
    end

    # Is the server running
    #
    # @return [Boolean] true if the server is running
    def running?
      @running
    end

    # Run the server
    #
    # @note This method blocks!
    def run
      raise 'Already running' if running?
      @stop = false
      @running = true
      begin
        mainloop until @stop
      ensure
        @running = false
        @server.close unless @server.closed?
        @ios
          .reject { |io| io == @server }
          .each { |io| close_connection(io) }
        File.unlink(@socket) if @socket rescue nil
      end
    end

    # Stop the server
    def stop
      raise 'Not running' unless running?
      @stop = true
      @server.close
      nil
    end

    private

    def mainloop
      if ready = IO.select(@reads, @writes, @ios, TIMEOUT)
        reads, writes, errors = ready
        errors.each { |io| close_connection(io) }

        @reads -= reads
        reads.each do |io|
          io == @server ? accept_connection : resume(io)
        end

        @writes -= writes
        writes.each { |io| resume(io) }
      end
    rescue SignalException => signal
      warn "Moneta::Server - received #{signal}"
      case signal.signo
      when Signal.list['INT'], Signal.list['TERM']
        @stop = true # graceful exit
      end
    rescue IOError => ex
      # We get a lot of these "closed stream" errors, which we ignore
      raise unless ex.message =~ /closed stream/
    rescue Errno::EBADF => ex
      warn "Moneta::Server - #{ex.message}"
    end

    def accept_connection
      io = @server.accept
      @connections[io] = Connection.new(io, @store)
      @ios << io
      resume(io)
    ensure
      @reads << @server
    end

    def delete_connection(io)
      @ios.delete(io)
      @reads.delete(io)
      @writes.delete(io)
    end

    def close_connection(io)
      delete_connection(io)
      @connections.delete(io).resume(:close)
    end

    def resume(io)
      case result = @connections[io].resume
      when :closed # graceful exit
        delete_connection(io)
      when Exception # messy exit
        delete_connection(io)
        raise result
      when :read
        @reads << io
      when :write
        @writes << io
      end
    end

    def start(options)
      if @socket = options[:socket]
        begin
          UNIXServer.open(@socket)
        rescue Errno::EADDRINUSE
          if client = (UNIXSocket.open(@socket) rescue nil)
            client.close
            raise
          end
          File.unlink(@socket)
          tries ||= 0
          (tries += 1) < 3 ? retry : raise
        end
      else
        TCPServer.open(options[:host] || '127.0.0.1', options[:port] || 9000)
      end
    end

    def stats
      {
        connections: @connections.length,
        reading: @reads.length,
        writing: @writes.length,
        total: @ios.length
      }
    end
  end
end
