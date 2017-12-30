describe "standard_client_tcp" do
  before :all do
    start_server(Moneta::Adapters::Memory.new)
  end

  moneta_store :Client
  moneta_specs STANDARD_SPECS

  it 'supports multiple clients' do
    client = Moneta.new(:Client)
    client['shared_key'] = 'shared_val'
    (1..100).each do |i|
      Thread.new do
        client = Moneta.new(:Client)
        (1.100).each do |j|
          client['shared_key'].should == 'shared_val'
          client["key-\#{j}-\#{i}"] = "val-\#{j}-\#{i}"
          client["key-\#{j}-\#{i}"].should == "val-\#{j}-\#{i}"
        end
      end
    end
  end
end
