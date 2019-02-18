describe 'standard_tokyotyrant_with_expires' do
  let(:t_res) { 0.125 }
  let(:min_ttl) { t_res }
  use_timecop

  moneta_store :TokyoTyrant, {expires: true}
  moneta_specs STANDARD_SPECS.with_expires
end
