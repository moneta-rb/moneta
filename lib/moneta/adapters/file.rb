require "fileutils"

module Moneta
  module Adapters
    class File
      include Moneta::Defaults

      def initialize(options = {})
        @directory = options[:path]
        if ::File.file?(@directory)
          raise StandardError, "The path you supplied #{@directory} is a file"
        elsif !::File.exists?(@directory)
          FileUtils.mkdir_p(@directory)
        end
      end

      def key?(key)
        ::File.exist?(path(key))
      end

      def [](key)
        if ::File.exist?(path(key))
          Marshal.load(::File.read(path(key)))
        end
      end

      def []=(key, value)
        ::File.open(path(key), "w") do |file|
          contents = Marshal.dump(value)
          file.puts(contents)
        end
      end

      def delete(key)
        value = self[key]
        FileUtils.rm(path(key))
        value
      rescue Errno::ENOENT
      end

      def clear
        FileUtils.rm_rf(@directory)
        FileUtils.mkdir(@directory)
      end

    private
      def path(key)
        ::File.join(@directory, key_for(key))
      end
    end
  end
end