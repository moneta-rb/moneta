describe 'adapter_mongo_moped_with_default_expires' do
  moneta_build do
    Moneta::Adapters::MongoMoped.new(db: "adapter_mongo",
                                     collection: 'moped_with_default_expires',
                                     expires: 1)
  end

  moneta_specs ADAPTER_SPECS.with_expires.with_default_expires.simplevalues_only
end
