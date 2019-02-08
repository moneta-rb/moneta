require 'dbm'

module Moneta
  module Adapters
    # DBM backend (Berkeley DB)
    # @api public
    class DBM < Memory
      # @param [Hash] options
      # @option options [String] :file Database file
      # @option options [::DBM] :backend Use existing backend instance
      def initialize(options = {})
        @backend = options[:backend] ||
          begin
            raise ArgumentError, 'Option :file is required' unless options[:file]
            ::DBM.new(options[:file])
          end
      end

      # (see Proxy#close)
      def close
        @backend.close
        nil
      end

      # (see Proxy#merge!)
      def merge!(pairs, options = {})
        hash =
          if block_given?
            keys = pairs.map { |k, _| k }
            old_pairs = Hash[slice(*keys)]
            Hash[pairs.map do |key, new_value|
              new_value = yield(key, old_pairs[key], new_value) if old_pairs.key?(key)
              [key, new_value]
            end.to_a]
          else
            Hash === pairs ? pairs : Hash[pairs.to_a]
          end

        @backend.update(hash)
        self
      end
    end
  end
end
