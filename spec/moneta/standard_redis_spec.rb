describe 'standard_redis' do
  let(:t_res){ 0.1 }
  let(:min_ttl){ t_res }

  moneta_store :Redis
  moneta_specs STANDARD_SPECS.with_native_expires
end
