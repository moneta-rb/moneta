describe 'standard_lruhash_with_expires' do
  moneta_store :LRUHash, {expires: true}
  moneta_specs STANDARD_SPECS.with_expires.without_persist
end
