require "yaml"
require "fileutils"

module Moneta
  module Adapters
    class YAML
      include Moneta::Defaults

      def initialize(options = {})
        @file = ::File.expand_path(options[:path])
        unless ::File.exists?(@file)
          ::File.open(@file, "w") { |file| file << {}.to_yaml }
        end
      end

      def key?(key, *)
        yaml.has_key?(key_for(key))
      end

      def [](key)
        string_key = key_for(key)
        yaml[string_key]['value'] if yaml.key?(string_key)
      end

      def store(key, value, *)
        hash = yaml
        (hash[key_for(key)] ||= {})['value'] = value
        save(hash)
      end

      def delete(key, *)
        hash = yaml
        value = self[key_for(key)]
        hash.delete(key_for(key))
        save(hash)
        value
      end

      def clear(*)
        save
      end

    private
      def yaml
        ::YAML.load_file(@file)
      end

      def save(hash = {})
        ::File.open(@file, "w") { |file| file << hash.to_yaml }
      end
    end
  end
end
