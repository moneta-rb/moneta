describe 'standard_restclient', isolate: true, adapter: :RestClient do
  before :all do
    start_restserver
  end

  moneta_store :RestClient,
                   {url: 'http://localhost:8808/moneta/'}

  moneta_specs STANDARD_SPECS.without_increment.without_create
end
