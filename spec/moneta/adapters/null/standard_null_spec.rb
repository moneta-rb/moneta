describe 'standard_null', adapter: :Null do
  moneta_store :Null
  moneta_specs STANDARD_SPECS.without_increment.without_create.without_store.without_persist
end
