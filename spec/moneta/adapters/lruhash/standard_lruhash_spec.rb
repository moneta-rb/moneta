describe 'standard_lruhash', adapter: :LRUHash do
  moneta_store :LRUHash
  moneta_specs STANDARD_SPECS.without_persist
end
