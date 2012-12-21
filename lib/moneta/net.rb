module Moneta
  # @api private
  module Net
    DEFAULT_PORT = 9000

    class Error < Exception; end

    def read(io)
      size = io.read(4).unpack('N').first
      Marshal.load(io.read(size))
    end

    def write(io, o)
      s = Marshal.dump(o)
      io.write([s.bytesize].pack('N') << s)
    end
  end
end
