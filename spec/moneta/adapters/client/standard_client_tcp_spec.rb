describe "standard_client_tcp", isolate: true, adapter: :Client do
  before :all do
    start_server(Moneta::Adapters::Memory.new)
  end

  moneta_store :Client
  moneta_specs STANDARD_SPECS

  it 'supports multiple clients' do
    store['shared_key'] = 'shared_val'
    threads = (1..100).map do |i|
      Thread.new do
        client = new_store
        (1..100).each do |j|
          client['shared_key'].should == 'shared_val'
          client["key-\#{j}-\#{i}"] = "val-\#{j}-\#{i}"
          client["key-\#{j}-\#{i}"].should == "val-\#{j}-\#{i}"
        end
      end
    end
    threads.map(&:join)
  end
end
