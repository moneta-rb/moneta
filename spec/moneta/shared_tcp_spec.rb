describe "shared_tcp", isolate: true do
  moneta_build do
    tempdir = self.tempdir
    Moneta.build do
      use(:Shared, port: 9001) do
        adapter :PStore, file: File.join(tempdir, 'shared_tcp')
      end
    end
  end

  moneta_specs ADAPTER_SPECS.with_each_key

  it 'shares values' do
    store['shared_key'] = 'shared_value'
    second = new_store
    second.key?('shared_key').should be true
    second['shared_key'].should == 'shared_value'
    second.close
  end
end
