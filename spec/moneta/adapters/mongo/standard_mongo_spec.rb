describe 'standard_mongo', adapter: :Mongo do
  let(:t_res) { 0.125 }
  let(:min_ttl) { t_res }

  moneta_store :Mongo, {db: File.basename(__FILE__, '.rb'), collection: 'default'}
  moneta_specs STANDARD_SPECS.with_native_expires.with_each_key
end
