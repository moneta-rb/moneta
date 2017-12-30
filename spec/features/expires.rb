shared_examples :expires do
  it 'supports expires on store and []', retry: 3 do
    store.store('key1', 'val1', expires: 3)
    store['key1'].should == 'val1'
    sleep 1
    store['key1'].should == 'val1'
    sleep 3
    store['key1'].should be_nil
  end

  it 'supports strict expires on store and []' do
    store.store('key1', 'val1', expires: 2)
    store['key1'].should == 'val1'
    sleep 3 # Sleep 3 seconds because after 2 seconds the value can still exist!
    store['key1'].should be_nil
  end

  it 'supports expires on store and fetch', retry: 3 do
    store.store('key1', 'val1', expires: 3)
    store.fetch('key1').should == 'val1'
    sleep 1
    store.fetch('key1').should == 'val1'
    sleep 3
    store.fetch('key1').should be_nil
  end

  it 'supports strict expires on store and fetch' do
    store.store('key1', 'val1', expires: 2)
    store.fetch('key1').should == 'val1'
    sleep 3 # Sleep 3 seconds because after 2 seconds the value can still exist!
    store.fetch('key1').should be_nil
  end

  it 'supports 0 as no-expires on store and []' do
    store.store('key1', 'val1', expires: 0)
    store['key1'].should == 'val1'
    sleep 2
    store['key1'].should == 'val1'
  end

  it 'supports false as no-expires on store and []' do
    store.store('key1', 'val1', expires: false)
    store['key1'].should == 'val1'
    sleep 2
    store['key1'].should == 'val1'
  end

  it 'supports expires on store and load', retry: 3 do
    store.store('key1', 'val1', expires: 3)
    store.load('key1').should == 'val1'
    sleep 1
    store.load('key1').should == 'val1'
    sleep 3
    store.load('key1').should be_nil
  end

  it 'supports strict expires on store and load' do
    store.store('key1', 'val1', expires: 2)
    store.load('key1').should == 'val1'
    sleep 3 # Sleep 3 seconds because after 2 seconds the value can still exist!
    store.load('key1').should be_nil
  end

  it 'supports expires on store and #key?', retry: 3 do
    store.store('key1', 'val1', expires: 3)
    store.key?('key1').should be true
    sleep 1
    store.key?('key1').should be true
    sleep 3
    store.key?('key1').should be false
  end

  it 'supports strict expires on store and #key?' do
    store.store('key1', 'val1', expires: 2)
    store.key?('key1').should be true
    sleep 3 # Sleep 3 seconds because after 2 seconds the value can still exist!
    store.key?('key1').should be false
  end

  it 'supports updating the expiration time in load', retry: 3 do
    store.store('key2', 'val2', expires: 3)
    store['key2'].should == 'val2'
    sleep 1
    store.load('key2', expires: 5).should == 'val2'
    store['key2'].should == 'val2'
    sleep 3
    store['key2'].should == 'val2'
    sleep 3
    store['key2'].should be_nil
  end

  it 'supports 0 as no-expires in load' do
    store.store('key1', 'val1', expires: 2)
    store.load('key1', expires: 0).should == 'val1'
    sleep 3
    store.load('key1').should == 'val1'
  end

  it 'supports false as no-expires in load' do
    store.store('key1', 'val1', expires: 2)
    store.load('key1', expires: false).should == 'val1'
    sleep 3
    store.load('key1').should == 'val1'
  end

  it 'supports updating the expiration time in #key?', retry: 3 do
    store.store('key2', 'val2', expires: 3)
    store['key2'].should == 'val2'
    sleep 1
    store.key?('key2', expires: 5).should be true
    store['key2'].should == 'val2'
    sleep 3
    store['key2'].should == 'val2'
    sleep 3
    store['key2'].should be_nil
  end

  it 'supports 0 as no-expires in #key?' do
    store.store('key1', 'val1', expires: 2)
    store.key?('key1', expires: 0).should be true
    sleep 3
    store['key1'].should == 'val1'
  end

  it 'supports false as no-expires in #key?' do
    store.store('key1', 'val1', expires: 2)
    store.key?('key1', expires: false ).should be true
    sleep 3
    store['key1'].should == 'val1'
  end

  it 'supports updating the expiration time in fetch', retry: 3 do
    store.store('key1', 'val1', expires: 3)
    store['key1'].should == 'val1'
    sleep 1
    store.fetch('key1', nil, expires: 5).should == 'val1'
    store['key1'].should == 'val1'
    sleep 3
    store['key1'].should == 'val1'
    sleep 3
    store['key1'].should be_nil
  end

  it 'supports 0 as no-expires in fetch' do
    store.store('key1', 'val1', expires: 2)
    store.fetch('key1', nil, expires: 0).should == 'val1'
    sleep 3
    store.load('key1').should == 'val1'
  end

  it 'supports false as no-expires in fetch' do
    store.store('key1', 'val1', expires: 2)
    store.fetch('key1', nil, expires: false).should == 'val1'
    sleep 3
    store.load('key1').should == 'val1'
  end

  it 'strictly respects expires in delete' do
    store.store('key2', 'val2', expires: 2)
    store['key2'].should == 'val2'
    sleep 3 # Sleep 3 seconds because after 2 seconds the value can still exist!
    store.delete('key2').should be_nil
  end

  it 'respects expires in delete', retry: 3 do
    store.store('key2', 'val2', expires: 3)
    store['key2'].should == 'val2'
    sleep 1
    store['key2'].should == 'val2'
    sleep 3
    store.delete('key2').should be_nil
  end

  it 'supports the #expires syntactic sugar', retry: 3 do
    store.store('persistent_key', 'persistent_value', expires: 0)
    store.expires(1).store('key2', 'val2')
    store['key2'].should == 'val2'
    sleep 2
    store.delete('key2').should be_nil
    store['persistent_key'].should == 'persistent_value'
  end

  it 'supports false as no-expires on store and []' do
    store.store('key1', 'val1', expires: false)
    store['key1'].should == 'val1'
    sleep 2
    store['key1'].should == 'val1'
  end

  it 'does not update the expiration time in #key? when not asked to do so', retry: 3 do
    store.store('key1', 'val1', expires: 1)
    store.key?('key1').should be true
    store.key?('key1', expires: nil).should be true
    sleep 2
    store.key?('key1').should be false
  end

  it 'does not update the expiration time in fetch when not asked to do so', retry: 3 do
    store.store('key1', 'val1', expires: 1)
    store.fetch('key1').should == 'val1'
    store.fetch('key1', expires: nil).should == 'val1'
    sleep 2
    store.fetch('key1').should be_nil
  end

  it 'does not update the expiration time in load when not asked to do so', retry: 3 do
    store.store('key1', 'val1', expires: 1)
    store.load('key1').should == 'val1'
    store.load('key1', expires: nil).should == 'val1'
    sleep 2
    store.load('key1').should be_nil
  end
end
