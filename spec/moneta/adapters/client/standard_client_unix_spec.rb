require_relative './client_helper.rb'

describe "standard_client_unix", adapter: :Client do
  include_context :start_server,
                  backend: ->{ Moneta::Adapters::Memory.new },
                  socket: ->{ File.join(tempdir, 'standard_client_unix') }

  moneta_store :Client do
    { socket: File.join(tempdir, 'standard_client_unix') }
  end

  moneta_specs STANDARD_SPECS
end
