require_relative '../faraday_helper.rb'
require_relative './helper.rb'

describe 'standard_restclient', adapter: :RestClient do
  include_context :faraday_adapter
  include_context :start_restserver, 11934

  moneta_store :RestClient do
    { url: 'http://localhost:11934/moneta', adapter: faraday_adapter }
  end

  moneta_specs STANDARD_SPECS.without_increment.without_create
end
