describe 'standard_mongo_official' do
  let(:t_res){ 0.1 }
  let(:min_ttl){ t_res }

  moneta_store :MongoOfficial, {db: 'standard_mongo', collection: 'official'}
  moneta_specs STANDARD_SPECS.with_each_key.with_native_expires
end
