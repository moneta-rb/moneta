begin
  require "fog"
rescue LoadError
  puts "You need the Fog gem to use the S3 moneta store"
  exit
end

module Moneta
  module Adapters
    class Fog
      include Moneta::Defaults

      def initialize(options = {})
        bucket = options.delete(:namespace)
        s3 = options.delete(:cloud).new(options)
        @directory = s3.directories.create(:key => bucket)
      end

      def key?(key)
        !@directory.files.head(key_for(key)).nil?
      end

      def [](key)
        if value = get(key)
          deserialize(value.body)
        end
      end

      def delete(key)
        value = get(key)
        if value
          value.destroy
          deserialize(value.body)
        end
      end

      def store(key, value, options = {})
        #perms = options[:perms]
        #headers = options[:headers] || {}
        @directory.files.create(:key => key_for(key), :body => serialize(value))
      end

      # def update_key(key, options = {})
      #   debug "update_key(key=#{key}, options=#{options.inspect})"
      #   k = s3_key(key, false)
      #   k.save_meta(meta_headers_from_options(options)) unless k.nil?
      # end

      def clear
        @directory.files.all.each do |file|
          file.destroy
        end
        self
      end

    private
      def get(key)
        @directory.files.get(key_for(key))
      end
    end
  end
end
