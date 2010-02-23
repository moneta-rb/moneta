begin
  require "active_record"
rescue LoadError
  puts "You need the activerecord gem in order to use the ActiveRecord moneta store"
  exit
end

module Moneta
  class ActiveRecord
    class Store < ::ActiveRecord::Base
      set_primary_key 'key'

      def parsed_value
        JSON.parse(value)['root']
      end
    end

    def initialize(options = {})
      @options = options
      Store.establish_connection(@options[:connection] || raise("Must specify :connection"))
      Store.set_table_name(@options[:table] || 'moneta_cache_store')
    end

    module Implementation
      def key?(key)
        !!self[key]
      end

      def has_key?(key)
        key?(key)
      end

      def [](key)
        record = Store.find_by_key(key)
        record ? record.parsed_value : nil
      end

      def []=(key, value)
        record = Store.find_by_key(key)
        if record
          record.update_attributes!(:value => {'root' => value}.to_json)
        else
          store = Store.new
          store.key = key
          store.value = {'root' => value}.to_json
          store.save!
        end
      end

      def fetch(key, value = nil)
        value ||= block_given? ? yield(key) : default # TODO: Shouldn't yield if key is present?
        self[key] || value
      end

      def delete(key)
        record = Store.find_by_key(key)
        if record
          record.destroy
          record.parsed_value
        end
      end

      def store(key, value, options = {})
        self[key] = value
      end

      def clear
        Store.delete_all
      end

    end

    # Unimplemented
    module Expiration
      def update_key(key, options)
      end
    end

    include Implementation
    include Expiration
  end
end
