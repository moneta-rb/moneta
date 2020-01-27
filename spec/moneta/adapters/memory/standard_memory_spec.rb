describe 'standard_memory', adapter: :Memory do
  moneta_store :Memory
  moneta_specs STANDARD_SPECS.without_persist.with_each_key
end
