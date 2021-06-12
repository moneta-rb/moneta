require 'tdb'

module Moneta
  module Adapters
    # TDB backend
    # @api public
    class TDB < Adapter
      include HashAdapter
      include IncrementSupport
      include EachKeySupport

      supports :create

      # @!method initialize(options = {})
      #   @param [Hash] options
      #   @option options [String] :file Database file
      #   @option options [::TDB] :backend Use existing backend instance
      backend { |file:, **options| ::TDB.new(file, options) }

      # (see Proxy#close)
      def close
        backend.close
        nil
      end

      # (see Proxy#create)
      def create(key, value, options = {})
        backend.insert!(key, value)
        true
      rescue ::TDB::ERR::EXISTS
        false
      end
    end
  end
end
