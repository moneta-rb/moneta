shared_examples :each_key do
  it 'returns an empty enum when there are no keys' do
    expect(store.each_key.count).to eq(0)
  end

  it 'returns collection with the stored key/s' do
    expect { store.store('1st_key', 'value') }
      .to change { store.each_key.to_a }
      .from([])
      .to(['1st_key'])

    expect { store.store('2nd_key', 'value') }
      .to change { store.each_key.to_a.sort }
      .from(['1st_key'])
      .to(['1st_key', '2nd_key'].sort)
  end

  it 'wont duplicate keys' do
    expect { 2.times { |i| store.store('a_key', "#{i}_val") } }
      .to change { store.each_key.to_a }
      .from([])
      .to(['a_key'])
  end

  it 'wont return deleted keys' do
    store.store('a_key', "a_val")
    store.store('b_key', "b_val")
    expect { store.delete('a_key') }
      .to change { store.each_key.to_a.sort }
      .from(['a_key', 'b_key'].sort)
      .to(['b_key'])
  end

  it 'yields the keys to the block and returns the store' do
    # Make a list of keys that we expect to find in the store
    keys = []
    2.times do |i|
      key = "key_#{i}"
      keys << key
      store.store(key, "#{i}_val")
    end

    # Enumerate the store, making store that at each iteration we find one of
    # the keys we are looking for
    expect(store.each_key do |k|
      expect(keys.delete(k)).not_to be_nil
    end).to eq(store)

    # To assert that all keys were seen by the block
    expect(keys).to be_empty
  end
end
