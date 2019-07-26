require 'rack/session/moneta'
require 'action_dispatch/middleware/session/abstract_store'

module ActionDispatch
  module Session
    # A Rails cache backed by any Moneta store
    class MonetaStore < Rack::Session::Moneta
      include Compatibility
      include StaleSessionCheck
      include SessionObject if defined?(SessionObject)
    end
  end
end
