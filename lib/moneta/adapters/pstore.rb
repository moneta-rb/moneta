require 'pstore'

module Moneta
  module Adapters
    class PStore < ::PStore
      include Moneta::Defaults

      def initialize(options = {})
        options[:path] ||= ::File.join Dir.pwd, 'data.pstore'
        super options[:path]
      end

      def key?(key)
        transaction do
          root? key_for(key)
        end
      end

      def keys
        transaction true do
          roots
        end
      end

      def [](key)
        transaction true do
          struct = super key_for(key)
          struct ? struct['value'] : nil
        end
      end

      def delete(key)
        struct = if @transaction
          super key_for(key)
        else
          transaction do
            super key_for(key)
          end
        end
        struct ? struct['value'] : nil
      end

      def store(key, value, *)
        transaction do
          (@table[key_for(key)] ||= {})['value'] = value
        end
      end

      def clear(*)
        transaction do
          @table.keys.each do |key|
            delete key
          end
        end
      end
    end
  end
end
