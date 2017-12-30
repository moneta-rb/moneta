describe 'adapter_mongo' do
  moneta_build do
    Moneta::Adapters::Mongo.new(db: "adapter_mongo",
                                collection: 'default')
  end

  moneta_specs ADAPTER_SPECS.with_native_expires.simplevalues_only
end
