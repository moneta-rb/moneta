shared_examples :null do
  it 'reads from keys like a Hash' do
    moneta_property_of(keys: 1).check do |m|
      store[m.keys[0]].should be_nil
      store.load(m.keys[0]).should be_nil
    end
  end

  it 'guarantees that the same value is returned when setting a key' do
    moneta_property_of(keys: 1, values: 1).check do |m|
      (store[m.keys[0]] = m.values[0]).should equal(m.values[0])
    end
  end

  it 'returns false from #key? if a key is not available' do
    moneta_property_of(keys: 1).check(1) do |m|
      store.key?(m.keys[0]).should be false
    end
  end

  it 'returns nil from delete if a value for a key does not exist' do
    moneta_property_of(keys: 1).check do |m|
      store.delete(m.keys[0]).should be_nil
    end
  end

  it 'removes all keys from the store with clear' do
    moneta_property_of(keys: 2, values: 2).check do |m|
      store[m.keys[0]] = m.values[0]
      store[m.keys[1]] = m.values[1]
      store.clear.should equal(store)
      store.key?(m.keys[0]).should be false
      store.key?(m.keys[1]).should be false
    end
  end

  it 'fetches a key with a default value with fetch, if the key is not available' do
    moneta_property_of(keys: 1, values: 1).check do |m|
      store.fetch(m.keys[0], m.values[0]).should == m.values[0]
    end
  end

  it 'fetches a key with a block with fetch, if the key is not available' do
    moneta_property_of(keys: 1, values: 1).check do |m|
      store.fetch(m.keys[0]) do |k|
        k.should equal(m.keys[0])
        m.values[0]
      end.should equal(m.values[0])
    end
  end

  it 'accepts frozen options' do
    moneta_property_of(keys: 1, values: 1).check do |m|
      options = {option1: 1, options2: 2}
      options.freeze
      store.clear.should equal(store)
      store.key?(m.keys[0], options).should be false
      store.load(m.keys[0], options).should be_nil
      store.fetch(m.keys[0], 42, options).should == 42
      store.fetch(m.keys[0], options) { 42 }.should == 42
      store.delete(m.keys[0], options).should be_nil
      store.clear(options).should equal(store)
      store.store(m.keys[0], m.values[0], options).should == m.values[0]
    end
  end
end
