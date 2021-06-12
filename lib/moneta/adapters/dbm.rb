require 'dbm'

module Moneta
  module Adapters
    # DBM backend (Berkeley DB)
    # @api public
    class DBM < Adapter
      include DBMAdapter
      include IncrementSupport
      include CreateSupport
      include EachKeySupport

      # @!method initialize(options = {})
      #   @param [Hash] options
      #   @option options [String] :file Database file
      #   @option options [::DBM] :backend Use existing backend instance
      backend { |file:| ::DBM.new(file) }
    end
  end
end
