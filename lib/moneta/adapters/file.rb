require 'fileutils'

module Moneta
  module Adapters
    # Filesystem backend
    # @api public
    class File
      include Defaults
      supports :create, :increment

      # @param [Hash] options
      # @option options [String] :dir Directory where files will be stored
      def initialize(options = {})
        raise ArgumentError, 'Option :dir is required' unless @dir = options[:dir]
        FileUtils.mkpath(@dir)
        raise "#{@dir} is not a directory" unless ::File.directory?(@dir)
      end

      # (see Proxy#key?)
      def key?(key, options = {})
        ::File.exist?(store_path(key))
      end

      # (see Proxy#load)
      def load(key, options = {})
        ::File.read(store_path(key))
      rescue Errno::ENOENT
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        temp_file = ::File.join(@dir, "value-#{$$}-#{Thread.current.object_id}")
        path = store_path(key)
        FileUtils.mkpath(::File.dirname(path))
        ::File.open(temp_file, 'wb') {|f| f.write(value) }
        ::File.rename(temp_file, path)
        value
      rescue Exception
        File.unlink(temp_file) rescue nil
        raise
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        value = load(key, options)
        ::File.unlink(store_path(key))
        value
      rescue Errno::ENOENT
      end

      # (see Proxy#clear)
      def clear(options = {})
        temp_dir = "#{@dir}-#{$$}-#{Thread.current.object_id}"
        ::File.rename(@dir, temp_dir)
        FileUtils.mkpath(@dir)
        self
      rescue Errno::ENOENT
        self
      ensure
        FileUtils.rm_rf(temp_dir)
      end

      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
        path = store_path(key)
        FileUtils.mkpath(::File.dirname(path))
        ::File.open(path, ::File::RDWR | ::File::CREAT) do |f|
          Thread.pass until f.flock(::File::LOCK_EX)
          content = f.read
          amount += Utils.to_int(content) unless content.empty?
          content = amount.to_s
          f.pos = 0
          f.write(content)
          f.truncate(content.bytesize)
          amount
        end
      end

      # HACK: The implementation using File::EXCL is not atomic under JRuby 1.7.4
      # See https://github.com/jruby/jruby/issues/827
      if defined?(JRUBY_VERSION)
        # (see Proxy#create)
        def create(key, value, options = {})
          path = store_path(key)
          FileUtils.mkpath(::File.dirname(path))
          # Call native java.io.File#createNewFile
          return false unless ::Java::JavaIo::File.new(path).createNewFile
          ::File.open(path, 'wb+') {|f| f.write(value) }
          true
        end
      else
        # (see Proxy#create)
        def create(key, value, options = {})
          path = store_path(key)
          FileUtils.mkpath(::File.dirname(path))
          ::File.open(path, ::File::WRONLY | ::File::CREAT | ::File::EXCL) do |f|
            f.binmode
            f.write(value)
          end
          true
        rescue Errno::EEXIST
          false
        end
      end

      protected

      def store_path(key)
        ::File.join(@dir, key)
      end
    end
  end
end
