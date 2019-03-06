describe "shared_unix", isolate: true, proxy: :Shared do
  moneta_build do
    tempdir = self.tempdir
    Moneta.build do
      use(:Shared, socket: File.join(tempdir, 'shared_unix.socket')) do
        adapter :PStore, file: File.join(tempdir, 'shared_unix')
      end
    end
  end

  shared_examples :shared_unix do
    moneta_specs ADAPTER_SPECS

    it 'shares values' do
      store['shared_key'] = 'shared_value'
      second = new_store
      second.key?('shared_key').should be true
      second['shared_key'].should == 'shared_value'
      second.close
    end
  end

  context "runnning as the server" do
    include_examples :shared_unix

    it "has the underlying adapter" do
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

    include_examples :shared_unix

    it 'has a client adapter' do
      store.load('dummy')
      expect(store.adapter).to be_a Moneta::Adapters::Client
    end
  end
end
