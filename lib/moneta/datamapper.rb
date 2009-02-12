begin
  gem "dm-core", "0.9.10"
  require "dm-core"
rescue LoadError
  puts "You need the dm-core gem in order to use the DataMapper moneta store"
  exit
end

class MonetaHash
  include DataMapper::Resource
  
  def self.default_repository_name
    :moneta
  end
  
  property :the_key, String, :key => true
  property :value, Object, :lazy => false
  property :expires, Time
  
  def self.value(key)
    obj = self.get(key)
    obj && obj.value
  end
end

module Moneta
  class DataMapper
    class Expiration
      def initialize(klass)
        @klass = klass
      end
      
      def [](key)
        if obj = get(key)
          obj.expires
        end
      end
      
      def []=(key, value)
        obj = get(key)
        obj.expires = value
        obj.save
      end
      
      def delete(key)
        obj = get(key)
        obj.expires = nil
        obj.save
      end
      
      private
      def get(key)
        @klass.get(key)
      end
    end
    
    def initialize(options = {})
      ::DataMapper.setup(:moneta, options[:setup])
      MonetaHash.auto_upgrade!
      @hash = MonetaHash
      @expiration = Expiration.new(MonetaHash)
    end
    
    module Implementation
      def key?(key)
        !!@hash.get(key)
      end
      
      def has_key?(key)
        !!@hash.get(key)
      end
      
      def [](key)
        @hash.value(key)
      end

      def []=(key, value)
        obj = @hash.get(key)
        if obj
          obj.update(key, value)
        else
          @hash.create(:the_key => key, :value => value)
        end
      end
      
      def fetch(key, default)
        self[key] || default
      end
      
      def delete(key)
        value = self[key]
        @hash.all(:the_key => key).destroy!
        value
      end
      
      def store(key, value, options = {})
        self[key] = value
      end
      
      def clear
        @hash.all.destroy!
      end
    end
    include Implementation
    include Expires
  end
end