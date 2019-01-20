describe "shared_unix", isolate: true do
  moneta_build do
    tempdir = self.tempdir
    Moneta.build do
      use(:Shared, socket: File.join(tempdir, 'shared_unix.socket')) do
        adapter :PStore, file: File.join(tempdir, 'shared_unix')
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
