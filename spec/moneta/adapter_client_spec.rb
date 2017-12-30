describe 'adapter_client' do
  before :all do
    start_server(Moneta::Adapters::Memory.new)
  end

  moneta_build do
    Moneta::Adapters::Client.new
  end

  moneta_specs ADAPTER_SPECS
end
