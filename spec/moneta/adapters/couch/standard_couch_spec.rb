require_relative '../faraday_helper.rb'

describe "standard_couch", adapter: :Couch do
  include_context :faraday_adapter

  moneta_store :Couch do
    { db: 'standard_couch', adapter: faraday_adapter }
  end

  moneta_loader do |value|
    ::Marshal.load(value.unpack('m').first)
  end

  moneta_specs STANDARD_SPECS.without_increment
end
