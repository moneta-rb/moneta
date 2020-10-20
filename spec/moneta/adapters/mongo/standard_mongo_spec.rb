describe 'standard_mongo', adapter: :Mongo do
  let(:t_res) { 0.125 }
  let(:min_ttl) { t_res }

  moneta_store :Mongo, {database: File.basename(__FILE__, '.rb'), collection: 'standard_mongo'}
  moneta_specs STANDARD_SPECS.with_native_expires.with_each_key
end
