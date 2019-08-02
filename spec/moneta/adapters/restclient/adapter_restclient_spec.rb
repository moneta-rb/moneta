require_relative '../faraday_helper.rb'
require_relative './helper.rb'

describe 'adapter_restclient', adapter: :RestClient do
  include_context :faraday_adapter
  include_context :start_restserver, 11933

  moneta_build do
    Moneta::Adapters::RestClient.new(url: 'http://localhost:11933/moneta', adapter: faraday_adapter)
  end

  moneta_specs ADAPTER_SPECS.without_increment.without_create
end
