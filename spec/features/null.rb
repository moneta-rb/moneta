shared_examples :null do
  it 'reads from keys like a Hash' do
    moneta_property_of(keys: 1).check do |keys:|
      store[keys[0]].should be_nil
      store.load(keys[0]).should be_nil
    end
  end

  it 'guarantees that the same value is returned when setting a key' do
    moneta_property_of(keys: 1, values: 1).check do |keys:, values:|
      (store[keys[0]] = values[0]).should equal(values[0])
    end
  end

  it 'returns false from #key? if a key is not available' do
    moneta_property_of(keys: 1).check(1) do |keys:|
      store.key?(keys[0]).should be false
    end
  end

  it 'returns nil from delete if a value for a key does not exist' do
    moneta_property_of(keys: 1).check do |keys:|
      store.delete(keys[0]).should be_nil
    end
  end

  it 'removes all keys from the store with clear' do
    moneta_property_of(keys: 2, values: 2).check do |keys:, values:|
      store[keys[0]] = values[0]
      store[keys[1]] = values[1]
      store.clear.should equal(store)
      store.key?(keys[0]).should be false
      store.key?(keys[1]).should be false
    end
  end

  it 'fetches a key with a default value with fetch, if the key is not available' do
    moneta_property_of(keys: 1, values: 1).check do |keys:, values:|
      store.fetch(keys[0], values[0]).should == values[0]
    end
  end

  it 'fetches a key with a block with fetch, if the key is not available' do
    moneta_property_of(keys: 1, values: 1).check do |keys:, values:|
      store.fetch(keys[0]) do |k|
        k.should equal(keys[0])
        values[0]
      end.should equal(values[0])
    end
  end

  it 'accepts frozen options' do
    moneta_property_of(keys: 1, values: 1).check do |keys:, values:|
      options = {option1: 1, options2: 2}
      options.freeze
      store.clear.should equal(store)
      store.key?(keys[0], options).should be false
      store.load(keys[0], options).should be_nil
      store.fetch(keys[0], 42, options).should == 42
      store.fetch(keys[0], options) { 42 }.should == 42
      store.delete(keys[0], options).should be_nil
      store.clear(options).should equal(store)
      store.store(keys[0], values[0], options).should == values[0]
    end
  end
end
