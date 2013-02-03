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
        FileUtils.rm_rf(temp_dir)
        self
      rescue Errno::ENOENT
        self
      end

      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
        path = store_path(key)
        if create(key, amount.to_s, options)
          amount
        else
          FileUtils.mkpath(::File.dirname(path))
          x = ::File.open(path, 'ab+') do |f|
            Thread.pass until f.flock(::File::LOCK_EX)
            value = Utils.to_int(f.read) + amount
            f.truncate(0)
            f.write(value.to_s)
            value
          end
        end
      end

      # (see Proxy#create)
      def create(key, value, options = {})
        path = store_path(key)
        FileUtils.mkpath(::File.dirname(path))
        ::File.open(path, ::File::WRONLY | ::File::CREAT | ::File::EXCL) do |file|
          file.binmode
          file.write(value)
        end
        true
      rescue Errno::EEXIST
        false
      end

      protected

      def store_path(key)
        ::File.join(@dir, key)
      end
    end
  end
end
