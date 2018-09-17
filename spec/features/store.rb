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

  shared_examples :values_at do |name|
    it 'retrieves stored values' do
      moneta_property_of(keys, keys, keys, values, values, values).
        check do |key1, key2, key3, val1, val2, val3|
          store[key1] = val1
          store[key2] = val2
          store[key3] = val3
          expect(store.public_send(name, key2, key3, key1)).to eq [val2, val3, val1]
          store.clear
        end
    end

    it 'returns nil in place of missing values' do
      moneta_property_of(keys, keys, keys, values, values).
        check do |key1, key2, key3, val1, val2|
          store[key1] = val1
          store[key2] = val2
          expect(store.public_send(name, key2, key3, key1)).to eq [val2, nil, val1]
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
      moneta_property_of(keys, keys, keys, keys, values, values, values).
        check do |key1, key2, key3, key4, val1, val2, val3|
          store[key1] = val1
          store[key2] = val2
          store[key3] = val3

          expect do |b|
            store.fetch_values(key1, key2, key3, key4, &b)
          end.to yield_with_args(key4)

          store.clear
        end
    end

    it 'uses the value of the block, if given, for keys that are not in the store' do
      moneta_property_of(keys, keys, keys, keys, values, values, values, values).
        check do |key1, key2, key3, key4, val1, val2, val3, val4|
          store[key1] = val1
          store[key2] = val2
          store[key3] = val3

          expect(store.fetch_values(key1, key2, key3, key4) do |key|
            expect(key).to eq key4
            val4
          end).to eq [val1, val2, val3, val4]

          store.clear
        end
    end

    it 'raises any error raised in the block' do
      expect { store.fetch_values('key') { raise 'yarg' } }.to raise_error 'yarg'
    end
  end

  describe '#slice' do
    it 'returns pairs of stored keys and values' do
      moneta_property_of(keys, keys, keys, values, values, values).
        check do |key1, key2, key3, val1, val2, val3|
          store[key1] = val1
          store[key2] = val2
          store[key3] = val3

          expect(store.slice(*[key1, key2, key3].shuffle).to_a).to \
            contain_exactly([key1, val1], [key2, val2], [key3, val3])

          store.clear
        end
    end

    it 'does not return pairs for any keys absent from the store' do
      moneta_property_of(keys, keys, keys, keys, values, values, values).
        check do |key1, key2, key3, key4, val1, val2, val3|
          store[key1] = val1
          store[key2] = val2
          store[key3] = val3

          expect(store.slice(*[key1, key2, key3, key4].shuffle).to_a).to \
            contain_exactly([key1, val1], [key2, val2], [key3, val3])

          store.clear
        end
    end
  end

  describe '#merge!' do
    shared_examples :merge! do
      it 'stores values' do
        moneta_property_of(keys, keys, keys, values, values, values).
          check do |key1, key2, key3, val1, val2, val3|
            expect(store.merge!(pairs.call(key1 => val1, key2 => val2, key3 => val3))).to be store
            expect(store.key?(key1)).to be true
            expect(store[key1]).to eq val1
            expect(store.key?(key2)).to be true
            expect(store[key2]).to eq val2
            expect(store.key?(key3)).to be true
            expect(store[key3]).to eq val3
            store.clear
          end
      end

      it 'overwrites existing values' do
        moneta_property_of(keys, keys, values, values, values).
          check do |key1, key2, val1, val2, val3|
            expect(store[key1] = val1).to eq val1
            expect(store.merge!(pairs.call(key1 => val2, key2 => val3))).to be store
            expect(store.key?(key1)).to be true
            expect(store[key1]).to eq val2
            expect(store.key?(key2)).to be true
            expect(store[key2]).to eq val3
            store.clear
          end
      end

      it 'stores the return value of the block, if given, for keys that will be overwritten' do
        moneta_property_of(keys, keys, values, values, values, values).
          check do |key1, key2, val1, val2, val3, val4|
            expect(store[key1] = val1).to eq val1
            expect(store.merge!(pairs.call(key1 => val2, key2 => val3)) do |key, old_val, new_val|
              expect(key).to eq key1
              expect(old_val).to eq val1
              expect(new_val).to eq val2
              val4
            end).to be store

            expect(store.key?(key1)).to be true
            expect(store[key1]).to eq val4
            expect(store.key?(key2)).to be true
            expect(store[key2]).to eq val3
            store.clear
          end
      end

      it 'raises any error raised in the block' do
        store['x'] = 'y'
        expect { store.merge!('x' => 'v') { raise 'yarg' } }.to raise_error 'yarg'
      end
    end

    context 'when passed a hash' do
      let(:pairs) { :itself.to_proc }
      include_examples :merge!
    end

    context 'when passed an array' do
      let(:pairs) { :to_a.to_proc }
      include_examples :merge!
    end

    context 'when passed an enumerator' do
      let :pairs do
        lambda do |hash|
          Enumerator.new do |y|
            hash.each(&y.method(:<<))
          end
        end
      end

      include_examples :merge!
    end
  end
end
