describe 'adapter_mongo_moped_with_default_expires', isolate: true, adapter: :Mongo do
  let(:t_res) { 0.125 }
  let(:min_ttl) { t_res }

  moneta_build do
    Moneta::Adapters::MongoMoped.new(db: "adapter_mongo",
                                     collection: 'moped_with_default_expires',
                                     expires: min_ttl)
  end

  moneta_specs ADAPTER_SPECS.with_each_key.with_expires.with_default_expires.simplevalues_only
end
