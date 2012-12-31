require 'daybreak'

module Moneta
  module Adapters
    # Daybreak backend
    # @api public
    class Daybreak
      include Defaults
      include HashAdapter

      # Disable serialization, we have `Moneta::Transformer` for that
      class DB < ::Daybreak::DB
        def serialize(value) value; end
        def parse(value) value; end
      end

      # @param [Hash] options
      # @option options [String] :file Database file
      def initialize(options = {})
        raise ArgumentError, 'Option :file is required' unless options[:file]
        @hash = DB.new(options[:file])
      end

      # (see Proxy#close)
      def close
        @hash.close!
        nil
      end
    end
  end
end
