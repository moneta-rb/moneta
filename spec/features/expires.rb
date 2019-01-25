shared_examples :expires do
  at_each_usec do
    it 'supports expires on store and []' do
      store.store('key1', 'val1', expires: min_ttl + t_res)
      store['key1'].should == 'val1'
      advance t_res
      store['key1'].should == 'val1'
      advance min_ttl + t_res
      store['key1'].should be_nil
    end

    it 'supports strict expires on store and []' do
      store.store('key1', 'val1', expires: min_ttl)
      store['key1'].should == 'val1'
      advance min_ttl + t_res
      store['key1'].should be_nil
    end

    it 'supports expires on store and fetch' do
      store.store('key1', 'val1', expires: min_ttl + t_res)
      store.fetch('key1').should == 'val1'
      advance t_res
      store.fetch('key1').should == 'val1'
      advance min_ttl + t_res
      store.fetch('key1').should be_nil
    end

    it 'supports strict expires on store and fetch' do
      store.store('key1', 'val1', expires: min_ttl)
      store.fetch('key1').should == 'val1'
      advance min_ttl + t_res
      store.fetch('key1').should be_nil
    end

    it 'supports 0 as no-expires on store and []' do
      store.store('key1', 'val1', expires: 0)
      store['key1'].should == 'val1'
      advance min_ttl
      store['key1'].should == 'val1'
    end

    it 'supports false as no-expires on store and []' do
      store.store('key1', 'val1', expires: false)
      store['key1'].should == 'val1'
      advance min_ttl
      store['key1'].should == 'val1'
    end

    it 'supports expires on store and load' do
      store.store('key1', 'val1', expires: min_ttl + t_res)
      store.load('key1').should == 'val1'
      advance t_res
      store.load('key1').should == 'val1'
      advance min_ttl + t_res
      store.load('key1').should be_nil
    end

    it 'supports strict expires on store and load' do
      store.store('key1', 'val1', expires: min_ttl)
      store.load('key1').should == 'val1'
      advance min_ttl + t_res
      store.load('key1').should be_nil
    end

    it 'supports expires on store and #key?' do
      store.store('key1', 'val1', expires: min_ttl + t_res)
      store.key?('key1').should be true
      advance t_res
      store.key?('key1').should be true
      advance min_ttl + t_res
      store.key?('key1').should be false
    end

    it 'supports strict expires on store and #key?' do
      store.store('key1', 'val1', expires: min_ttl)
      store.key?('key1').should be true
      advance min_ttl + t_res
      store.key?('key1').should be false
    end

    it 'supports updating the expiration time in load' do
      store.store('key2', 'val2', expires: min_ttl + t_res)
      store['key2'].should == 'val2'
      advance t_res
      store.load('key2', expires: min_ttl * 2 + t_res).should == 'val2'
      store['key2'].should == 'val2'
      advance min_ttl + t_res
      store['key2'].should == 'val2'
      advance min_ttl + t_res
      store['key2'].should be_nil
    end

    it 'supports 0 as no-expires in load' do
      store.store('key1', 'val1', expires: min_ttl)
      store.load('key1', expires: 0).should == 'val1'
      advance min_ttl + t_res
      store.load('key1').should == 'val1'
    end

    it 'supports false as no-expires in load' do
      store.store('key1', 'val1', expires: min_ttl)
      store.load('key1', expires: false).should == 'val1'
      advance min_ttl + t_res
      store.load('key1').should == 'val1'
    end

    it 'supports updating the expiration time in #key?' do
      store.store('key2', 'val2', expires: min_ttl + t_res)
      store['key2'].should == 'val2'
      advance t_res
      store.key?('key2', expires: min_ttl * 2 + t_res).should be true
      store['key2'].should == 'val2'
      advance min_ttl + t_res
      store['key2'].should == 'val2'
      advance min_ttl + t_res
      store['key2'].should be_nil
    end

    it 'supports 0 as no-expires in #key?' do
      store.store('key1', 'val1', expires: min_ttl)
      store.key?('key1', expires: 0).should be true
      advance min_ttl + t_res
      store['key1'].should == 'val1'
    end

    it 'supports false as no-expires in #key?' do
      store.store('key1', 'val1', expires: min_ttl)
      store.key?('key1', expires: false).should be true
      advance min_ttl + t_res
      store['key1'].should == 'val1'
    end

    it 'supports updating the expiration time in fetch' do
      store.store('key1', 'val1', expires: min_ttl + t_res)
      store['key1'].should == 'val1'
      advance t_res
      store.fetch('key1', nil, expires: min_ttl * 2 + t_res).should == 'val1'
      store['key1'].should == 'val1'
      advance min_ttl + t_res
      store['key1'].should == 'val1'
      advance min_ttl + t_res
      store['key1'].should be_nil
    end

    it 'supports 0 as no-expires in fetch' do
      store.store('key1', 'val1', expires: min_ttl)
      store.fetch('key1', nil, expires: 0).should == 'val1'
      advance min_ttl + t_res
      store.load('key1').should == 'val1'
    end

    it 'supports false as no-expires in fetch' do
      store.store('key1', 'val1', expires: min_ttl)
      store.fetch('key1', nil, expires: false).should == 'val1'
      advance min_ttl + t_res
      store.load('key1').should == 'val1'
    end

    it 'strictly respects expires in delete' do
      store.store('key2', 'val2', expires: min_ttl)
      store['key2'].should == 'val2'
      advance min_ttl + t_res
      store.delete('key2').should be_nil
    end

    it 'respects expires in delete' do
      store.store('key2', 'val2', expires: min_ttl + t_res)
      store['key2'].should == 'val2'
      advance t_res
      store['key2'].should == 'val2'
      advance min_ttl + t_res
      store.delete('key2').should be_nil
    end

    it 'supports the #expires syntactic sugar' do
      store.store('persistent_key', 'persistent_value', expires: 0)
      store.expires(min_ttl).store('key2', 'val2')
      store['key2'].should == 'val2'
      advance min_ttl + t_res
      store.delete('key2').should be_nil
      store['persistent_key'].should == 'persistent_value'
    end

    it 'supports false as no-expires on store and []' do
      store.store('key1', 'val1', expires: false)
      store['key1'].should == 'val1'
      advance min_ttl
      store['key1'].should == 'val1'
    end

    it 'does not update the expiration time in #key? when not asked to do so' do
      store.store('key1', 'val1', expires: min_ttl)
      store.key?('key1').should be true
      store.key?('key1', expires: nil).should be true
      advance min_ttl + t_res
      store.key?('key1').should be false
    end

    it 'does not update the expiration time in fetch when not asked to do so' do
      store.store('key1', 'val1', expires: min_ttl)
      store.fetch('key1').should == 'val1'
      store.fetch('key1', expires: nil).should == 'val1'
      advance min_ttl + t_res
      store.fetch('key1').should be_nil
    end

    it 'does not update the expiration time in load when not asked to do so' do
      store.store('key1', 'val1', expires: min_ttl)
      store.load('key1').should == 'val1'
      store.load('key1', expires: nil).should == 'val1'
      advance min_ttl + t_res
      store.load('key1').should be_nil
    end
  end
end
