require 'sdbm'

module Moneta
  module Adapters
    # SDBM backend
    # @api public
    class SDBM < Adapter
      include DBMAdapter
      include IncrementSupport
      include CreateSupport
      include EachKeySupport

      # @!method initialize(options = {})
      #   @param [Hash] options
      #   @option options [String] :file Database file
      #   @option options [::SDBM] :backend Use existing backend instance
      backend { |file:| ::SDBM.new(file) }
    end
  end
end
