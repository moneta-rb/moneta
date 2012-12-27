require 'fileutils'

module Moneta
  module Adapters
    # Filesystem backend
    # @api public
    class File
      include Defaults
      include IncrementSupport

      # @param [Hash] options
      # @option options [String] :dir Directory where files will be stored
      def initialize(options = {})
        raise ArgumentError, 'Option :dir is required' unless @dir = options[:dir]
        FileUtils.mkpath(@dir)
        raise "#{@dir} is not a directory" unless ::File.directory?(@dir)
      end

      # @see Proxy#key?
      def key?(key, options = {})
        ::File.exist?(store_path(key))
      end

      # @see Proxy#load
      def load(key, options = {})
        ::File.read(store_path(key))
      rescue Errno::ENOENT
      end

      # @see Proxy#store
      def store(key, value, options = {})
        path = store_path(key)
        temp_file = ::File.join(@dir, "value-#{$$}-#{Thread.current.object_id}")
        FileUtils.mkpath(::File.dirname(path))
        ::File.open(temp_file, 'wb') {|file| file.write(value) }
        ::File.unlink(path) if ::File.exist?(path)
        ::File.rename(temp_file, path)
        value
      rescue Errno::ENOENT
        ::File.unlink(temp_file) rescue nil
        value
      end

      # @see Proxy#delete
      def delete(key, options = {})
        value = load(key, options)
        ::File.unlink(store_path(key))
        value
      rescue Errno::ENOENT
      end

      # @see Proxy#clear
      def clear(options = {})
        temp_dir = "#{@dir}-#{$$}-#{Thread.current.object_id}"
        ::File.rename(@dir, temp_dir)
        FileUtils.mkpath(@dir)
        FileUtils.rm_rf(temp_dir)
        self
      rescue Errno::ENOENT
        self
      end

      # @see Proxy#increment
      def increment(key, amount = 1, options = {})
        lock(key) { super }
      end

      protected

      def lock(key, &block)
        path = store_path(key)
        return yield unless ::File.exist?(path)
        ::File.open(path, 'r+') do |f|
          begin
            f.flock ::File::LOCK_EX
            yield
          ensure
            f.flock ::File::LOCK_UN
          end
        end
      end

      def store_path(key)
        ::File.join(@dir, key)
      end
    end
  end
end
