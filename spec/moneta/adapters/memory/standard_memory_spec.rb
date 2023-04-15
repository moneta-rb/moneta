describe 'standard_memory', adapter: :Memory do
  moneta_store :Memory
  moneta_specs STANDARD_SPECS.without_persist
end
