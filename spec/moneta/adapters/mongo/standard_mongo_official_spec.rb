describe 'standard_mongo_official', adapter: :Mongo do
  let(:t_res) { 0.125 }
  let(:min_ttl) { t_res }

  moneta_store :MongoOfficial, {db: File.basename(__FILE__, '.rb'), collection: 'official'}
  moneta_specs STANDARD_SPECS.with_native_expires.with_each_key
end
