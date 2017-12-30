describe 'standard_memory_with_expires' do
  moneta_store :Memory, {expires: true}
  moneta_specs STANDARD_SPECS.with_expires.without_persist
end
