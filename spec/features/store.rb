shared_examples :store do
  it 'writes values to keys that like a Hash' do
    moneta_property_of(keys: 1, values: 1).check do |m|
      store[m.keys[0]] = m.values[0]
      store[m.keys[0]].should == m.values[0]
      store.load(m.keys[0]).should == m.values[0]
    end
  end

  it 'returns true from #key? if a key is available' do
    moneta_property_of(keys: 1, values: 1).check do |m|
      store[m.keys[0]] = m.values[0]
      store.key?(m.keys[0]).should be true
    end
  end

  it 'stores values with #store' do
    moneta_property_of(keys: 1, values: 1).check do |m|
      value = m.values[0]
      store.store(m.keys[0], value).should equal(value)
      store[m.keys[0]].should == m.values[0]
      store.load(m.keys[0]).should == m.values[0]
    end
  end

  it 'stores values after clear' do
    moneta_property_of(keys: 2, values: 2).check do |m|
      store[m.keys[0]] = m.values[0]
      store[m.keys[1]] = m.values[1]
      store.clear.should equal(store)
      store[m.keys[0]] = m.values[0]
      store[m.keys[0]].should == m.values[0]
      store[m.keys[1]].should be_nil
    end
  end

  it 'removes and returns a value from the backing store via delete if it exists' do
    moneta_property_of(keys: 1, values: 1).check do |m|
      store[m.keys[0]] = m.values[0]
      store.delete(m.keys[0]).should == m.values[0]
      store.key?(m.keys[0]).should be false
    end
  end

  it 'overwrites existing values' do
    moneta_property_of(keys: 1, values: 2).check do |m|
      store[m.keys[0]] = m.values[0]
      store[m.keys[0]].should == m.values[0]
      store[m.keys[0]] = m.values[1]
      store[m.keys[0]].should == m.values[1]
    end
  end

  it 'stores frozen values' do
    moneta_property_of(keys: 1, values: 1).check do |m|
      value = m.values[0].freeze
      (store[m.keys[0]] = value).should equal(value)
      store[m.keys[0]].should == m.values[0]
    end
  end

  it 'stores frozen keys' do
    moneta_property_of(keys: 1, values: 1).check do |m|
      key = m.keys[0].freeze
      store[key] = m.values[0]
      store[m.keys[0]].should == m.values[0]
    end
  end

  it 'fetches a key with a default value with fetch, if the key is available' do
    moneta_property_of(keys: 1, values: 2).check do |m|
      next if m.values[0].nil?
      store[m.keys[0]] = m.values[0]
      store.fetch(m.keys[0], m.values[1]).should == m.values[0]
    end
  end

  it 'does not run the block in fetch if the key is available' do
    moneta_property_of(keys: 1, values: 1).check do |m|
      next if m.values[0].nil?
      store[m.keys[0]] = m.values[0]
      unaltered = 'unaltered'
      store.fetch(m.keys[0]) { unaltered = 'altered' }
      unaltered.should == 'unaltered'
    end
  end

  shared_examples :values_at do |name|
    it 'retrieves stored values' do
      moneta_property_of(keys: 3, values: 3).check do |m|
        store[m.keys[0]] = m.values[0]
        store[m.keys[1]] = m.values[1]
        store[m.keys[2]] = m.values[2]
        expect(store.public_send(name, m.keys[1], m.keys[2], m.keys[0])).to eq [m.values[1], m.values[2], m.values[0]]
        store.clear
      end
    end

    it 'returns nil in place of missing values' do
      moneta_property_of(keys: 3, values: 2).check do |m|
        store[m.keys[0]] = m.values[0]
        store[m.keys[1]] = m.values[1]
        expect(store.public_send(name, m.keys[1], m.keys[2], m.keys[0])).to eq [m.values[1], nil, m.values[0]]
        store.clear
      end
    end
  end

  describe '#values_at' do
    include_examples :values_at, :values_at
  end

  describe '#fetch_values' do
    include_examples :values_at, :fetch_values

    it 'yields to the block, if given, for keys that are not in the store' do
      moneta_property_of(keys: 4, values: 3).check do |m|
        store[m.keys[0]] = m.values[0]
        store[m.keys[1]] = m.values[1]
        store[m.keys[2]] = m.values[2]

        expect do |b|
          store.fetch_values(m.keys[0], m.keys[1], m.keys[2], m.keys[3], &b)
        end.to yield_with_args(m.keys[3])

        store.clear
      end
    end

    it 'uses the value of the block, if given, for keys that are not in the store' do
      moneta_property_of(keys: 4, values: 4).check do |m|
        store[m.keys[0]] = m.values[0]
        store[m.keys[1]] = m.values[1]
        store[m.keys[2]] = m.values[2]

        expect(store.fetch_values(m.keys[0], m.keys[1], m.keys[2], m.keys[3]) do |key|
          expect(key).to eq m.keys[3]
          m.values[3]
        end).to eq [m.values[0], m.values[1], m.values[2], m.values[3]]

        store.clear
      end
    end

    it 'raises any error raised in the block' do
      expect { store.fetch_values('key') { raise 'yarg' } }.to raise_error 'yarg'
    end
  end

  describe '#slice' do
    it 'returns pairs of stored keys and values' do
      moneta_property_of(keys: 3, values: 3).check do |m|
        store[m.keys[0]] = m.values[0]
        store[m.keys[1]] = m.values[1]
        store[m.keys[2]] = m.values[2]

        expect(store.slice(*[m.keys[0], m.keys[1], m.keys[2]].shuffle).to_a).to \
          contain_exactly([m.keys[0], m.values[0]], [m.keys[1], m.values[1]], [m.keys[2], m.values[2]])

        store.clear
      end
    end

    it 'does not return pairs for any keys absent from the store' do
      moneta_property_of(keys: 4, values: 3).check do |m|
        store[m.keys[0]] = m.values[0]
        store[m.keys[1]] = m.values[1]
        store[m.keys[2]] = m.values[2]

        expect(store.slice(*[m.keys[0], m.keys[1], m.keys[2], m.keys[3]].shuffle).to_a).to \
          contain_exactly([m.keys[0], m.values[0]], [m.keys[1], m.values[1]], [m.keys[2], m.values[2]])

        store.clear
      end
    end
  end

  shared_examples :merge! do
    it 'can be called with an empty object' do
      expect { store.public_send(method, pairs.call({})) }.not_to raise_error
    end

    it 'stores values' do
      moneta_property_of(keys: 3, values: 3).check do |m|
        expect(store.public_send(method, pairs.call({ m.keys[0] => m.values[0], m.keys[1] => m.values[1], m.keys[2] => m.values[2] }))).to be store
        expect(store.key?(m.keys[0])).to be true
        expect(store[m.keys[0]]).to eq m.values[0]
        expect(store.key?(m.keys[1])).to be true
        expect(store[m.keys[1]]).to eq m.values[1]
        expect(store.key?(m.keys[2])).to be true
        expect(store[m.keys[2]]).to eq m.values[2]
        store.clear
      end
    end

    it 'overwrites existing values' do
      moneta_property_of(keys: 2, values: 3).check do |m|
        expect(store[m.keys[0]] = m.values[0]).to eq m.values[0]
        expect(store.public_send(method, pairs.call({ m.keys[0] => m.values[1], m.keys[1] => m.values[2] }))).to be store
        expect(store.key?(m.keys[0])).to be true
        expect(store[m.keys[0]]).to eq m.values[1]
        expect(store.key?(m.keys[1])).to be true
        expect(store[m.keys[1]]).to eq m.values[2]
        store.clear
      end
    end

    it 'stores the return value of the block, if given, for keys that will be overwritten' do
      moneta_property_of(keys: 2, values: 4).check do |m|
        expect(store[m.keys[0]] = m.values[0]).to eq m.values[0]
        expect(store.public_send(method, pairs.call({ m.keys[0] => m.values[1], m.keys[1] => m.values[2] })) do |key, old_val, new_val|
          expect(key).to eq m.keys[0]
          expect(old_val).to eq m.values[0]
          expect(new_val).to eq m.values[1]
          m.values[3]
        end).to be store

        expect(store.key?(m.keys[0])).to be true
        expect(store[m.keys[0]]).to eq m.values[3]
        expect(store.key?(m.keys[1])).to be true
        expect(store[m.keys[1]]).to eq m.values[2]
        store.clear
      end
    end

    it 'raises any error raised in the block' do
      store['x'] = 'y'
      expect { store.public_send(method, 'x' => 'v') { raise 'yarg' } }.to raise_error 'yarg'
    end
  end

  shared_examples :merge_or_update do
    context 'when passed a hash' do
      let(:pairs) { :itself.to_proc }
      include_examples :merge!
    end

    context 'when passed an array' do
      let(:pairs) { :to_a.to_proc }
      include_examples :merge!
    end

    context 'when passed a lazy enumerator' do
      let :pairs do
        lambda do |hash|
          Enumerator.new do |y|
            hash.each(&y.method(:<<))
          end.lazy
        end
      end

      include_examples :merge!
    end
  end

  describe '#merge!' do
    let(:method) { :merge! }
    include_examples :merge_or_update
  end

  describe '#update' do
    let(:method) { :update }
    include_examples :merge_or_update
  end
end
