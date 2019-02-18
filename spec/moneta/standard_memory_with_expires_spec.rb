describe 'standard_memory_with_expires' do
  let(:t_res) { 0.125 }
  let(:min_ttl) { t_res }
  use_timecop

  moneta_store :Memory, {expires: true}
  moneta_specs STANDARD_SPECS.with_expires.without_persist
end
