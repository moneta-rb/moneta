require 'gdbm'

module Moneta
  module Adapters
    # GDBM backend
    # @api public
    class GDBM < Adapter
      include DBMAdapter
      include IncrementSupport
      include CreateSupport
      include EachKeySupport

      # @!method initialize(options = {})
      #   @param [Hash] options
      #   @option options [String] :file Database file
      #   @option options [::GDBM] :backend Use existing backend instance
      backend { |file:| ::GDBM.new(file) }
    end
  end
end
