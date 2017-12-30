describe 'standard_mongo_official' do
  moneta_store :MongoOfficial, {db: 'standard_mongo', collection: 'official'}
  moneta_specs STANDARD_SPECS.with_native_expires
end
