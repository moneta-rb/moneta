describe 'expires_file', proxy: :Expires do
  let(:t_res) { 0.125 }
  let(:min_ttl) { 0.5 }

  use_timecop

  moneta_build do
    tempdir = self.tempdir
    Moneta.build do
      use :Expires
      use :Transformer, key: [:marshal, :escape], value: :marshal
      adapter :File, dir: File.join(tempdir, "expires-file")
    end
  end

  moneta_specs STANDARD_SPECS.with_expires.stringvalues_only

  it 'deletes expired value in underlying file storage' do
    store.store('foo', 'bar', expires: 2)
    store['foo'].should == 'bar'
    sleep 1
    store['foo'].should == 'bar'
    sleep 2
    store['foo'].should be_nil
    store.adapter['foo'].should be_nil
    store.adapter.adapter['foo'].should be_nil
  end
end
