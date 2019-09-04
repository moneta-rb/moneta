describe 'adapter_client', isolate: true, adapter: :Client do
  before :all do
    @server = start_server(Moneta::Adapters::Memory.new)
  end

  after :all do
    @server.stop
  end

  moneta_build do
    Moneta::Adapters::Client.new
  end

  moneta_specs ADAPTER_SPECS.with_each_key
end
