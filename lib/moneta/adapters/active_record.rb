begin
  require 'active_record'
rescue LoadError
  puts "You need the activerecord gem in order to use the ActiveRecord moneta store"
end

require 'yaml'

module Moneta
  module Adapters
    class ActiveRecord
      include Moneta::Defaults

      def initialize(options = {})
        @options = options
        unless self.class.const_defined?('Store')
          self.class.const_set('Store', Class.new(::ActiveRecord::Base)) # this prevents loading issues when active_record gem is unavailable
          Store.set_table_name(@options[:table] || 'moneta_store')
        end

        if @options[:connection]
          Store.establish_connection @options[:connection]
        end
      end

      def migrate
        unless Store.table_exists?
          Store.connection.create_table Store.table_name do |t|
            t.string   'key', :primary => :true
            t.string   'value'
          end
        end
      end

      def key?(key)
        record = Store.find_by_key key_for(key)
        !record.nil?
      end

      def [](key)
        record = Store.find_by_key key_for(key)
        record ? deserialize(record.value) : nil
      end

      def delete(key)
        record = Store.find_by_key key_for(key)
        if record
          Store.where(:key => key_for(record.key)).delete_all
          deserialize record.value
        end
      end

      def store(key, value, options = {})
        record = Store.find_by_key key_for(key)
        record ||= Store.new :key => key_for(key)
        record.value = serialize(value)
        record.save!
        value
      end

      def clear
        Store.delete_all
      end

    private
      
      def serialize(value)
        value.to_yaml
      end
      def deserialize(value)
        YAML::load value
      end
    end
  end
end
