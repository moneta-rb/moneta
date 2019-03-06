describe 'standard_mongo_moped', adapter: :Mongo do
  let(:t_res) { 0.125 }
  let(:min_ttl) { t_res }

  moneta_store :MongoMoped, {db: 'standard_mongo', collection: 'moped'}
  moneta_specs STANDARD_SPECS.with_native_expires
end
