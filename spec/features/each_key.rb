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
    2.times { |i| store.store("key_#{i}", "#{i}_val") }

    i = 0
    expect(store.each_key do |k|
      expect(k).to eq("key_#{i}")
      i += 1
    end).to eq(store)

    # To assert that the loop inside the block run
    expect(i).to eq(2)
  end
end
