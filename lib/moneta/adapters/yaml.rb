require 'yaml/store'

module Moneta
  module Adapters
    # YAML::Store backend
    # @api public
    class YAML < PStore
      # @!method initialize(options = {})
      #   @param [Hash] options
      #   @option options [YAML::Store] :backend YAML store to use
      #   @option options [String] :file YAML file to open - required unless using :backend
      #   @option options [Boolean] :threadsafe (false) Makes the YAML store thread-safe
      #   @option options Other options passed to `YAML::Store#new`
      backend { |file:, threadsafe: false, **options| ::YAML::Store.new(file, threadsafe, options) }
    end
  end
end
