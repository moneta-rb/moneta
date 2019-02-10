require 'tdb'

module Moneta
  module Adapters
    # TDB backend
    # @api public
    class TDB
      include Defaults
      include HashAdapter
      include IncrementSupport
      include CreateSupport
      include EachKeySupport

      # @param [Hash] options
      # @option options [String] :file Database file
      # @option options [::TDB] :backend Use existing backend instance
      def initialize(options)
        @backend = options[:backend] ||
          begin
            raise ArgumentError, 'Option :file is required' unless file = options.delete(:file)
            ::TDB.new(file, options)
          end
      end

      # (see Proxy#close)
      def close
        @backend.close
        nil
      end
    end
  end
end
