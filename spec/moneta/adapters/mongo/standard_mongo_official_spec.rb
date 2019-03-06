describe 'standard_mongo_official', adapter: :Mongo do
  let(:t_res) { 0.125 }
  let(:min_ttl) { t_res }

  moneta_store :MongoOfficial, {db: 'standard_mongo', collection: 'official'}
  moneta_specs STANDARD_SPECS.with_native_expires
end
