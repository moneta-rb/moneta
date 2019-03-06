describe 'adapter_restclient', isolate: true, adapter: :RestClient do
  before :all do
    start_restserver
  end

  moneta_build do
    Moneta::Adapters::RestClient.new(url: 'http://localhost:8808/moneta/')
  end

  moneta_specs ADAPTER_SPECS.without_increment.without_create
end
