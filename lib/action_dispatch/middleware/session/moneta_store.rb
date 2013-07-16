require 'rack/session/moneta'
require 'action_dispatch/middleware/session/abstract_store'

module ActionDispatch
  module Session
    class MonetaStore < Rack::Session::Moneta
      include Compatibility
      include StaleSessionCheck
      include SessionObject if defined?(SessionObject)
    end
  end
end
