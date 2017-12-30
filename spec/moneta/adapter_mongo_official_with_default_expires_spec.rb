describe 'adapter_mongo_official_with_default_expires' do
  moneta_build do


    Moneta::Adapters::MongoOfficial.new(db: "adapter_mongo",
                                        collection: 'official_with_default_expires',
                                        expires: 1)
  end

  moneta_specs ADAPTER_SPECS.with_expires.with_default_expires.simplevalues_only
end
