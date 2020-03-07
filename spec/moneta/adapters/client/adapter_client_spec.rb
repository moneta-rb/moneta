require_relative './client_helper.rb'

describe 'adapter_client', adapter: :Client do
  include_context :start_server, port: 9002, backend: ->{ Moneta::Adapters::Memory.new }

  moneta_build do
    Moneta::Adapters::Client.new(port: 9002)
  end

  moneta_specs ADAPTER_SPECS.with_each_key
end
