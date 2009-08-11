require "yaml"
require "fileutils"

module Moneta
  class YAML
    class Expiration
      def initialize(file)
        @file = file
      end
      
      def [](key)
        yaml[key]['expires'] if yaml.has_key?(key)
      end
      
      def []=(key, value)
        hash = yaml
        if hash.has_key?(key)
          hash[key]['expires'] = value
          save(hash)
        end
      end
      
      def delete(key)
        hash = yaml
        if hash.has_key?(key)
          hash[key].delete("expires")
          save(hash)
        end
      end

      private
      def yaml
        ::YAML.load_file(@file)
      end

      def save(hash)
        ::File.open(@file, "w") { |file| file << hash.to_yaml }
      end
    end
    
    def initialize(options = {})
      @file = File.expand_path(options[:path])
      unless ::File.exists?(@file)
        File.open(@file, "w") { |file| file << {}.to_yaml }
      end
 
      @expiration = Expiration.new(@file)
    end
    
    module Implementation
      def key?(key)
        yaml.has_key?(key)
      end
      
      alias has_key? key?
      
      def [](key)
        yaml[key]['value'] if yaml.has_key?(key)
      end
      
      def []=(key, value)
        hash = yaml
        (hash[key] ||= {})['value'] = value
        save(hash)
      end
            
      def delete(key)
        hash = yaml
        value = self[key]
        hash.delete(key)
        save(hash)
        value
      end
            
      def clear
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
    include Implementation
    include Defaults
    include Expires
  end
end
