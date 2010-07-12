#
#  Basic File Store
#  by Hampton Catlin
#
#  This cache simply uses a directory that it creates
#  and manages to keep your file stores.
#
#  Specify :skip_expires => true if you aren't using
#  expiration as this will slightly decrease your file size
#  and memory footprint of the library
#
#  You can optionally also specify a :namespace
#  option that will create a subfolder.
#


require 'fileutils'
require "moneta"

module Moneta
  module Adapters
    class BasicFile
      include Moneta::Defaults

      def initialize(options = {})
        @namespace = options[:namespace]
        @directory = ::File.join(options[:path], @namespace.to_s)

        ensure_directory_created(@directory)
      end

      def key?(key)
        !self[key].nil?
      end

      def [](key)
        if ::File.exist?(path(key))
          raw_get(key)
        end
      end

      def raw_get(key)
        Marshal.load(::File.read(path(key)))
      end

      def []=(key, value)
        store(key, value)
      end

      def store(key, value, options = {})
        ensure_directory_created(::File.dirname(path(key)))
        ::File.open(path(key), "w") do |file|
          contents = Marshal.dump(value)
          file.puts(contents)
        end
      end

      def update_key(key, options)
        store(key, self[key], options)
      end

      def delete!(key)
        FileUtils.rm(path(key))
        nil
      rescue Errno::ENOENT
      end

      def delete(key)
        value = self[key]
        delete!(key)
        value
      end

      def clear
        FileUtils.rm_rf(@directory)
        FileUtils.mkdir(@directory)
      end

    private
      def path(key)
        ::File.join(@directory, key_for(key))
      end

      def ensure_directory_created(directory_path)
        if ::File.file?(directory_path)
          raise StandardError, "The path you supplied #{directory_path} is a file"
        elsif !::File.exists?(directory_path)
          FileUtils.mkdir_p(directory_path)
        end
      end
    end
  end
end