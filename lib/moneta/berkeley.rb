begin
  require 'bdb'
rescue LoadError
  puts "You need bdb gem to use Bdb moneta store"
  exit
end

module Moneta
  
  class Berkeley
    
    def initialize(options={})
      file = options[:file]
      @db = Bdb::Db.new()
      @db.open(nil, file, nil, Bdb::Db::BTREE, Bdb::DB_CREATE, 0)
      unless options[:skip_expires]
        @expiration = Moneta::Berkeley.new(:file => "#{file}_expiration", :skip_expires => true )
        self.extend(Expires)
        #
        # specific Berkeley expiration fonctionality. Berkeley DB can't store Time object, only String.
        #
        self.extend(BerkeleyExpires)
      end
    end
    
    module BerkeleyExpires
      #
      # This specific extension convert Time into integer and then into string.
      #
      def check_expired(key)
        if @expiration[key] && Time.now > Time.at(@expiration[key].to_i)
          @expiration.delete(key)
          self.delete(key)
        end
      end
      
      private
      def update_options(key, options)
        if options[:expires_in]
          @expiration[key] = (Time.now + options[:expires_in]).to_i.to_s
        end
      end
    end
  
    module Implementation
      def key?(key)
        nil | self[key]
      end
  
      alias has_key? key?
  
      def []=(key,value)
        @db[key] = value
      end
  
      def store(key, value, options={})
        @db[key] = value
      end
  
      def [](key)
        @db[key]
      end
  
      def fetch(key, default)
        self[key] || default
      end
  
      def delete(key)
        value = self[key]
        @db.del(nil,key,0) if value
        value
      end
  
      def clear
        @db.truncate(nil)
      end
    end

    include Implementation
    
  end

end