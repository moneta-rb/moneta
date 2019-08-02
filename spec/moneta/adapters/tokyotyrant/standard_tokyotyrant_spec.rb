require_relative './helper.rb'

describe 'standard_tokyotyrant', adapter: :TokyoTyrant do
  include_context :start_tokyotyrant, 10655
  moneta_store :TokyoTyrant, port: 10655
  moneta_specs STANDARD_SPECS
end
