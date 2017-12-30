describe 'standard_redis' do
  moneta_store :Redis
  moneta_specs STANDARD_SPECS.with_native_expires
end
