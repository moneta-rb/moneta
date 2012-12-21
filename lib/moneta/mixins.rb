module Moneta
  # @api private
  module Mixins
    module IncrementSupport
      def increment(key, amount = 1, options = {})
        value = load(key, options)
        intvalue = value.to_i
        raise 'Tried to increment non integer value' unless value == nil || intvalue.to_s == value.to_s
        intvalue += amount
        store(key, intvalue.to_s, options)
        intvalue
      end
    end

    module HashAdapter
      def initialize(options = {})
        @hash = {}
      end

      def key?(key, options = {})
        @hash.has_key?(key)
      end

      def load(key, options = {})
        @hash[key]
      end

      def store(key, value, options = {})
        @hash[key] = value
      end

      def delete(key, options = {})
        @hash.delete(key)
      end

      def clear(options = {})
        @hash.clear
        self
      end
    end
  end
end
