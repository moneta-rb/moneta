describe "shared_tcp", isolate: true, proxy: :Shared do
  moneta_build do
    tempdir = self.tempdir
    Moneta.build do
      use(:Shared, port: 9001) do
        adapter :PStore, file: File.join(tempdir, 'shared_tcp')
      end
    end
  end

  shared_examples :shared_tcp do
    moneta_specs ADAPTER_SPECS

    it 'shares values' do
      store['shared_key'] = 'shared_value'
      second = new_store
      second.key?('shared_key').should be true
      second['shared_key'].should == 'shared_value'
      second.close
    end
  end

  # The first store initialised will be running the server
  context "running as the server" do
    include_examples :shared_tcp

    it 'has the underlying adapter' do
      store.load('dummy')
      expect(store.adapter.adapter).to be_a Moneta::Adapters::PStore
    end
  end

  context "running as a client" do
    let!(:server_store) do
      new_store.tap { |store| store.load('dummy') } # Makes a connection
    end

    after do
      server_store.close
    end

    include_examples :shared_tcp

    it 'has a client adapter' do
      store.load('dummy')
      expect(store.adapter).to be_a Moneta::Adapters::Client
    end
  end
end
