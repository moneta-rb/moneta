describe 'standard_memory_with_prefix' do
  moneta_store :Memory, {prefix: "moneta"}
  moneta_specs STANDARD_SPECS.without_persist
end
