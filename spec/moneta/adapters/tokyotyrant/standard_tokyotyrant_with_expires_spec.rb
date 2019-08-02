require_relative './helper.rb'

describe 'standard_tokyotyrant_with_expires', adapter: :TokyoTyrant do
  let(:t_res) { 0.125 }
  let(:min_ttl) { t_res }
  use_timecop

  include_context :start_tokyotyrant, 10656

  moneta_store :TokyoTyrant, expires: true, port: 10656
  moneta_specs STANDARD_SPECS.with_expires
end
