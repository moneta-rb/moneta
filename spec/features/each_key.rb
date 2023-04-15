shared_examples :each_key do
  shared_examples "enumerable" do
    it 'returns an empty enum when there are no keys' do
      expect(each_key.call.count).to eq(0)
    end

    it 'returns collection with the stored key/s' do
      moneta_property_of(keys: 2).check do |m|
        store.clear
        key1, key2 = m.keys
        store.store(key1, 'value')
        expect(each_key.call.to_a).to contain_exactly(key1)

        store.store(m.keys[1], 'value')
        expect(each_key.call.to_a).to contain_exactly(key1, key2)
      end
    end

    it 'when a lazy size implementation exist it returns the size of the collection or nil' do
      expect(store.each_key.size).to eq(nil) | eq(0)

      if !store.each_key.size.nil? && store.each_key.size.zero?
        expect { store.store('1st_key', 'value') }
          .to change { store.each_key.size }
          .from(0)
          .to(1)

        expect { store.store('2nd_key', 'value') }
          .to change { store.each_key.size }
          .from(1)
          .to(2)

        expect { store.delete('1st_key') }
          .to change { store.each_key.size }
          .from(2)
          .to(1)
      end
    end

    it 'doesn\'t duplicate keys' do
      expect { 2.times { |i| store.store('a_key', "#{i}_val") } }
        .to change { each_key.call.to_a }
        .from([])
        .to(['a_key'])
    end

    it 'doesn\'t return deleted keys' do
      store.store('a_key', "a_val")
      store.store('b_key', "b_val")
      expect { store.delete('a_key') }
        .to change { each_key.call.to_a.sort }
        .from(['a_key', 'b_key'].sort)
        .to(['b_key'])
    end

    it 'allows checking and retrieving entries while enumerating' do
      store['a'] = 'b'
      store['c'] = 'd'
      each_key.call do |k|
        val = if k == 'a' then 'b' else 'd' end
        expect(store.key?(k)).to be true
        expect(store[k]).to eq val
        expect(store.fetch(k)).to eq val
      end
    end
  end

  context "when a block is not given" do
    let(:each_key) do
      store.method(:each_key)
    end

    include_examples 'enumerable'

    it "returns the store if a block is given to #each" do
      expect(store.each_key.each.each.each{}).to eq store
    end
  end

  context "when a block is given" do
    let :each_key do
      proc do |&block|
        if block
          store.each_key(&block)
        else
          Enumerator.new do |y|
            store.each_key(&y.method(:<<))
          end
        end
      end
    end

    include_examples 'enumerable'

    it 'yields the keys to the block' do
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

    it "returns the store" do
      expect(store.each_key{}).to eq store
    end
  end
end
