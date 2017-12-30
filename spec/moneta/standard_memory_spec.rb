describe 'standard_memory' do
  moneta_store :Memory
  moneta_specs STANDARD_SPECS.without_persist
end
