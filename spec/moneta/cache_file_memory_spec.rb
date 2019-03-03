describe 'cache_file_memory' do
  moneta_build do
    tempdir = self.tempdir
    Moneta.build do
      use(:Cache) do
        adapter { adapter :File, dir: File.join(tempdir, "cache_file_memory") }
        cache { adapter :Memory }
      end
    end
  end

  moneta_specs ADAPTER_SPECS.returnsame.with_each_key

  it 'stores loaded values in cache' do
    store.adapter['foo'] = 'bar'
    store.cache['foo'].should be_nil
    store['foo'].should == 'bar'
    store.cache['foo'].should == 'bar'
    store.adapter.delete('foo')
    store['foo'].should == 'bar'
    store.delete('foo')
    store['foo'].should be_nil
  end
end
