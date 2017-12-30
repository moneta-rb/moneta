describe 'standard_lruhash' do
  moneta_store :LRUHash
  moneta_specs STANDARD_SPECS.without_persist
end
