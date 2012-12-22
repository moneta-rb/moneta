module Moneta
  # @api private
  module Mixins
    module WithOptions
      def with(options)
        list = [:key?, :load, :store, :delete, :increment, :clear]
        if options.include?(:only)
          raise ArgumentError, 'Either :only or :except is allowed' if options.include?(:except)
          list = [options.delete(:only)].compact.flatten
        elsif options.include?(:except)
          list -= [options.delete(:except)].compact.flatten
        end
        map = {}
        list.each {|method| (map[method] ||= {}).merge!(options) }
        OptionMerger.new(self, map)
      end

      def raw
        @raw_store ||=
          begin
            store = with(:raw => true, :only => [:load, :store, :delete])
            store.instance_variable_set(:@raw_store, store)
            store
          end
      end
    end

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
