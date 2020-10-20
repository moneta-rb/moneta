describe 'adapter_mongo', adapter: :Mongo do
  let(:t_res) { 0.125 }
  let(:min_ttl) { t_res }

  let(:database) { File.basename(__FILE__, '.rb') }

  moneta_build do
    Moneta::Adapters::Mongo.new(
      database: database,
      collection: 'adapter_mongo'
    )
  end

  moneta_specs ADAPTER_SPECS.with_each_key.with_native_expires.simplevalues_only

  it 'automatically deletes expired document' do
    store.store('key', 'val', expires: 5)

    i = 0
    query = store.instance_variable_get(:@collection).find(_id: ::BSON::Binary.new('key'))
    while i < 70 && query.first
      i += 1
      sleep 1 # Mongo needs up to 60 seconds
    end

    i.should be > 0 # Indicates that it took at least one sleep to expire
    query.count.should == 0
  end

  it 'uses the database specified via the :database option' do
    expect(store.backend.database.name).to eq database
  end

  it 'uses the database specified via the :db option' do
    store = Moneta::Adapters::Mongo.new(
      db: database,
      collection: 'adapter_mongo'
    )
    expect(store.backend.database.name).to eq database
  end
end
