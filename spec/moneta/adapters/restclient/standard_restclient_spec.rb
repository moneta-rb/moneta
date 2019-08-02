require_relative './helper.rb'

describe 'standard_restclient', adapter: :RestClient do
  include_context :start_restserver, 11934

  moneta_store :RestClient do
    { url: 'http://localhost:11934/moneta' }
  end

  moneta_specs STANDARD_SPECS.without_increment.without_create
end
