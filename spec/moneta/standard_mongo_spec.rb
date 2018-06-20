describe 'standard_mongo' do
  let(:t_res){ 0.1 }
  let(:min_ttl){ t_res }

  moneta_store :Mongo, {db: 'standard_mongo', collection: 'default'}
  moneta_specs STANDARD_SPECS.with_each_key.with_native_expires
end
