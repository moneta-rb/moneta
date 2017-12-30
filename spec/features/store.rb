shared_examples :store do
  it 'writes values to keys that like a Hash' do
    moneta_property_of(keys,values).check do |key1,val1|
      store[key1] = val1
      store[key1].should == val1
      store.load(key1).should == val1
    end
  end

  it 'returns true from #key? if a key is available' do
    moneta_property_of(keys,values).check do |key1,val1|
      store[key1] = val1
      store.key?(key1).should be true
    end
  end

  it 'stores values with #store' do
    moneta_property_of(keys,values).check do |key1,val1|
      value = val1
      store.store(key1, value).should equal(value)
      store[key1].should == val1
      store.load(key1).should == val1
    end
  end

  it 'stores values after clear' do
    moneta_property_of(keys,keys,values,values).check do |key1,key2,val1,val2|
      store[key1] = val1
      store[key2] = val2
      store.clear.should equal(store)
      store[key1] = val1
      store[key1].should == val1
      store[key2].should be_nil
    end
  end

  it 'removes and returns a value from the backing store via delete if it exists' do
    moneta_property_of(keys,values).check do |key1,val1|
      store[key1] = val1
      store.delete(key1).should == val1
      store.key?(key1).should be false
    end
  end

  it 'overwrites existing values' do
    moneta_property_of(keys,values,values).check do |key1,val1,val2|
      store[key1] = val1
      store[key1].should == val1
      store[key1] = val2
      store[key1].should == val2
    end
  end

  it 'stores frozen values' do
    moneta_property_of(keys,values).check do |key1,val1|
      value = val1.freeze
      (store[key1] = value).should equal(value)
      store[key1].should == val1
    end
  end

  it 'stores frozen keys' do
    moneta_property_of(keys,values).check do |key1,val1|
      key = key1.freeze
      store[key] = val1
      store[key1].should == val1
    end
  end

  it 'fetches a key with a default value with fetch, if the key is available' do
    moneta_property_of(keys,values,values).check do |key1,val1,val2|
      next if val1.nil?
      store[key1] = val1
      store.fetch(key1, val2).should == val1
    end
  end

  it 'does not run the block in fetch if the key is available' do
    moneta_property_of(keys,values).check do |key1,val1|
      next if val1.nil?
      store[key1] = val1
      unaltered = 'unaltered'
      store.fetch(key1) { unaltered = 'altered' }
      unaltered.should == 'unaltered'
    end
  end
end
