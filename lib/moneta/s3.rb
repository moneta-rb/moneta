begin
  require "right_aws"
rescue LoadError
  puts "You need the RightScale AWS gem to use the S3 moneta store"
  exit  
end

module Moneta  
  class S3
    # Initialize the Moneta::S3 store.
    #
    # Required values passed in the options hash:
    # * <tt>:access_key_id</tt>: The access id key
    # * <tt>:secret_access_key</tt>: The secret key
    # * <tt>:bucket</tt>: The name of bucket. Will be created if it doesn't
    # exist.
    def initialize(options = {})
      validate_options(options)
      logger = Logger.new(STDOUT)
      logger.level = Logger::INFO
      s3 = RightAws::S3.new(
        options[:access_key_id], 
        options[:secret_access_key], 
        {:logger => logger}
      )
      @bucket = s3.bucket(options.delete(:bucket), true)
    end
    
    def key?(key)
      !s3_key(key).nil?
    end
    
    alias has_key? key?
    
    def [](key)
      get(key)
    end
    
    def []=(key, value)
      store(key, value)
    end
    
    def fetch(key, default)
      self[key] || default
    end
    
    def delete(key)
      k = s3_key(key)
      if k
        value = k.get
        k.delete
        value
      end
    end
    
    # Store the key/value pair.
    # 
    # Options:
    # *<tt>:meta_headers</tt>: Meta headers passed to S3
    # *<tt>:perms</tt>: Permissions passed to S3
    # *<tt>:headers</tt>: Headers sent as part of the PUT request
    # *<tt>:expires_in</tt>: Number of seconds until expiration
    def store(key, value, options = {})
      meta_headers = meta_headers_from_options(options)
      perms = options[:perms]
      headers = options[:headers]
      
      case value
      when IO
        @bucket.put(key, value.read, meta_headers, perms)
      else
        @bucket.put(key, value, meta_headers, perms)
      end
    end
    
    def update_key(key, options = {})
      k = s3_key(key)
      k.save_meta(meta_headers_from_options(options)) unless k.nil?
    end
    
    def clear
      @bucket.clear
    end
    
    private
    def validate_options(options)
      unless options[:access_key_id]
        raise RuntimeError, ":access_key_id is required in options"
      end
      unless options[:secret_access_key]
        raise RuntimeError, ":secret_access_key is required in options"
      end
      unless options[:bucket]
        raise RuntimeError, ":bucket is required in options"
      end
    end
    
    def get(key)
      k = s3_key(key)
      k.nil? ? nil : k.get
    end
    
    def s3_key(key)
      begin
        s3_key = @bucket.key(key, true)
        if s3_key.meta_headers.has_key?('expires-at')
          expires_at = Time.parse(s3_key.meta_headers['expires-at'])
          if Time.now > expires_at
            # TODO delete the object?
            return nil
          end
        end
        s3_key.exists? ? s3_key : nil
      rescue RightAws::AwsError => e
        return nil
      end
    end
    
    def meta_headers_from_options(options={})
      meta_headers = options[:meta_headers] || {}
      if options[:expires_in]
        meta_headers['expires-at'] = (Time.now + options[:expires_in]).rfc2822
      end
      meta_headers
    end
  end
end
