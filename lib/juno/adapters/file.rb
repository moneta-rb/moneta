require 'fileutils'

module Juno
  module Adapters
    # Filesystem backend
    # @api public
    class File < Base
      def initialize(options = {})
        raise 'No option :dir specified' unless @dir = options[:dir]
        FileUtils.mkpath(@dir)
        raise "#{@dir} is not a dir" unless ::File.directory?(@dir)
      end

      def key?(key, options = {})
        ::File.exist?(store_path(key))
      end

      def load(key, options = {})
        ::File.read(store_path(key))
      rescue Errno::ENOENT
      end

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

      def delete(key, options = {})
        value = load(key, options)
        ::File.unlink(store_path(key))
        value
      rescue Errno::ENOENT
      end

      def clear(options = {})
        temp_dir = "#{@dir}-#{$$}-#{Thread.current.object_id}"
        ::File.rename(@dir, temp_dir)
        FileUtils.mkpath(@dir)
        FileUtils.rm_rf(temp_dir)
        self
      rescue Errno::ENOENT
        self
      end

      protected

      def store_path(key)
        ::File.join(@dir, key)
      end
    end
  end
end
