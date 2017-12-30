describe 'standard_mongo_moped' do
  moneta_store :MongoMoped, {db: 'standard_mongo', collection: 'moped'}
  moneta_specs STANDARD_SPECS.with_native_expires
end
