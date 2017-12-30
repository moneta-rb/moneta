describe 'standard_mongo' do
  moneta_store :Mongo, {db: 'standard_mongo', collection: 'default'}
  moneta_specs STANDARD_SPECS.with_native_expires
end
