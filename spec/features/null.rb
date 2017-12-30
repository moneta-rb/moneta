shared_examples :null do
  it 'reads from keys like a Hash' do
    moneta_property_of(keys).check do |key1|
      store[key1].should be_nil
      store.load(key1).should be_nil
    end
  end

  it 'guarantees that the same value is returned when setting a key' do
    moneta_property_of(keys, values).check do |key1,val1|
      (store[key1] = val1).should equal(val1)
    end
  end

  it 'returns false from #key? if a key is not available' do
    moneta_property_of(keys).check(1) do |key1|
      store.key?(key1).should be false
    end
  end

  it 'returns nil from delete if a value for a key does not exist' do
    moneta_property_of(keys).check do |key1|
      store.delete(key1).should be_nil
    end
  end

  it 'removes all keys from the store with clear' do
    moneta_property_of(keys, keys, values, values).check do |key1,key2,val1,val2|
      store[key1] = val1
      store[key2] = val2
      store.clear.should equal(store)
      store.key?(key1).should be false
      store.key?(key2).should be false
    end
  end

  it 'fetches a key with a default value with fetch, if the key is not available' do
    moneta_property_of(keys, values).check do |key1, val1|
      store.fetch(key1, val1).should == val1
    end
  end

  it 'fetches a key with a block with fetch, if the key is not available' do
    moneta_property_of(keys, values).check do |key1,val1|
      key = key1
      value = val1
      store.fetch(key) do |k|
        k.should equal(key)
        value
      end.should equal(value)
    end
  end

  it 'accepts frozen options' do
    moneta_property_of(keys, values).check do |key1,val1|
      options = {option1: 1, options2: 2}
      options.freeze
      store.clear.should equal(store)
      store.key?(key1, options).should be false
      store.load(key1, options).should be_nil
      store.fetch(key1, 42, options).should == 42
      store.fetch(key1, options) { 42 }.should == 42
      store.delete(key1, options).should be_nil
      store.clear(options).should equal(store)
      store.store(key1, val1, options).should == val1
    end
  end
end
