begin
  require "xattr"
rescue LoadError
  puts "You need the xattr gem to use the Xattr moneta store"
  exit
end
require "fileutils"

module Moneta
  module Adapters
    class Xattr
      include Defaults

      def initialize(options = {})
        file = options[:file]
        @hash = ::Xattr.new(file)
        FileUtils.mkdir_p(::File.dirname(file))
        FileUtils.touch(file)
      end

      def key?(key, *)
        @hash.list.include?(key_for(key))
      end

      def [](key)
        string_key = key_for(key)
        return nil unless key?(string_key)
        Marshal.load(@hash.get(string_key))
      end

      def store(key, value, *)
        @hash.set(key_for(key), Marshal.dump(value))
      end

      def delete(key, *)
        return nil unless key?(key)
        value = self[key]
        @hash.remove(key_for(key))
        value
      end

      def clear(*)
        @hash.list.each do |item|
          @hash.remove(item)
        end
      end

    end
  end
end
