shared_examples :metadata do
  it 'allows instantiation using a :metadata option' do
    store = new_store(metadata: [:type, :name, :thing])
    expect(store.metadata_names).to include(:type, :name, :thing)
  end

  context 'with metadata fields specified' do
    let(:store_with_metadata) { new_store(metadata: %i{type name}) }

    it 'ignores unknown metadata keys' do
      store_with_metadata.store('x', 'y', metadata: {name: 'test', _unknown: 'test2'})
      expect(store_with_metadata.load('x', return_metadata: true)).not_to respond_to(:_unknown)
    end

    describe '#create' do
      it 'allows storing metadata using the :metadata option' do
        expect(store_with_metadata.create('x', 'y', metadata: {name: 'test', type: 'thing'})).to be true
        expect(store_with_metadata.load('x', return_metadata: true).to_h).to match a_hash_including(name: 'test', type: 'thing', value: 'y')
      end
    end

    describe '#delete' do
      it 'returns a struct containing the value and metadata if :return_metadata is true' do
        store_with_metadata.store('x', 'q', metadata: {name: 'testing'})
        struct = store_with_metadata.delete('x', return_metadata: true)

        expect(store_with_metadata.key?('x')).to be false
        expect(struct).to be_a Struct
        expect(struct.to_h).to match a_hash_including(name: 'testing', value: 'q', type: nil)
      end
    end

    describe '#fetch_values' do
      it 'returns an array of structs if :return_metadata is true' do
        store_with_metadata.store('x', '1', metadata: {name: 'test1'})
        store_with_metadata.store('y', '2', metadata: {name: 'test2'})

        structs = store_with_metadata.fetch_values('x', 'y', 'z', return_metadata: true)
        expect(structs[0..1]).to all be_a Struct
        expect(structs[2]).to be nil
        expect(structs[0..1].map(&:to_h)).to match([
          a_hash_including(value: '1', name: 'test1', type: nil),
          a_hash_including(value: '2', name: 'test2', type: nil)
        ])
      end

      it 'yields missing keys to the block, and uses the return values with nil metadata' do
        store_with_metadata.store('x', '1', metadata: {name: 'test1'})
        store_with_metadata.store('y', '2', metadata: {name: 'test2'})

        structs = store_with_metadata.fetch_values('x', 'y', 'z', return_metadata: true) do |key|
          expect(key).to eq 'z'
          'yielded value'
        end

        expect(structs).to all be_a Struct
        expect(structs.map(&:to_h)).to match([
          a_hash_including(value: '1', name: 'test1', type: nil),
          a_hash_including(value: '2', name: 'test2', type: nil),
          a_hash_including(value: 'yielded value', name: nil, type: nil)
        ])
      end
    end

    describe '#load' do
      it 'returns a struct if the key is found and :return_metadata is true' do
        store_with_metadata.store('x', 'q', metadata: {name: 'testing'})
        struct = store_with_metadata.load('x', return_metadata: true)
        expect(struct).to be_a Struct
        expect(struct.to_h).to match a_hash_including(value: 'q', name: 'testing', type: nil)
      end

      it 'returns nil if the key is not found and :return_metadata is true' do
        struct = store_with_metadata.load('x', return_metadata: true)
        expect(struct).to be nil
      end
    end

    describe '#merge!' do
      it 'accepts a :metadata option, which allows assigning the same metadata to all values' do
        store_with_metadata.merge!(
          {
            'x' => '1',
            'y' => '2'
          },
          metadata: {
            name: 'test1',
            type: 'q'
          }
        )

        expect(store_with_metadata.values_at('x', 'y', return_metadata: true).map(&:to_h)).to match([
          a_hash_including(value: '1', name: 'test1', type: 'q'),
          a_hash_including(value: '2', name: 'test1', type: 'q')
        ])
      end
      
      it 'accepts a :yield_metadata option, which causes structs to be yielded to the given block' do
        block = double('block')

        expect(block).to receive(:call) do |key, old_struct, new_struct|
          expect(key).to eq('x')
          expect([old_struct, new_struct]).to all be_a Struct
          expect(old_struct.to_h).to match a_hash_including(value: '3', name: 'some test', type: nil)
          expect(new_struct.to_h).to match a_hash_including(value: '1', name: nil, type: nil)

          new_struct.type = 'test'
          new_struct
        end

        store_with_metadata.store('x', '3', metadata: {name: 'some test'})
        expect(store_with_metadata.merge!(
            {
              'x' => '1',
              'y' => '2'
            },
            yield_metadata: true,
            &block.method(:call)
        )).to be store_with_metadata

        expect(store_with_metadata.load('x', return_metadata: true).to_h).to include(name: nil, type: 'test')
      end

      it 'accepts both :metadata and :yield_metadata options together' do
        block = double('block')

        expect(block).to receive(:call) do |key, old_struct, new_struct|
          expect(key).to eq('x')
          expect([old_struct, new_struct]).to all be_a Struct
          expect(old_struct.to_h).to match a_hash_including(value: '3', name: 'some test', type: nil)
          expect(new_struct.to_h).to match a_hash_including(value: '1', name: 'testing', type: 'z')

          new_struct.type = 'r'
          new_struct
        end

        store_with_metadata.store('x', '3', metadata: {name: 'some test'})
        expect(store_with_metadata.merge!(
            {
              'x' => '1',
              'y' => '2'
            },
            metadata: {
              name: 'testing',
              type: 'z'
            },
            yield_metadata: true,
            &block.method(:call)
        )).to be store_with_metadata

        expect(store_with_metadata.load('x', return_metadata: true).to_h).to include(name: 'testing', type: 'r')
      end
    end

    describe '#slice' do
      it 'accepts a :return_metadata option, which causes structs to be returned' do
        store_with_metadata.store('x', '1', metadata: { name: 'test x', type: 'w' })
        store_with_metadata.store('y', '2', metadata: { name: 'test y', type: 'z' })

        pairs = store_with_metadata.slice('x', 'y', 'z', return_metadata: true)
        hash = Hash[pairs]

        expect(hash.values).to all be_a Struct
        expect(hash.transform_values(&:to_h)).to match(
          'x' => a_hash_including(
            value: '1',
            name: 'test x',
            type: 'w'
          ),
          'y' => a_hash_including(
            value: '2',
            name: 'test y',
            type: 'z'
          )
        )
      end
    end

    describe '#store' do
      it 'accepts a :metadata option, allowing metadata to be stored' do
        expect(store_with_metadata.store('x', '1', metadata: { name: 'test' })).to eq '1'
        expect(store_with_metadata.load('x', return_metadata: true).to_h).to match a_hash_including(
          value: '1',
          name: 'test',
          type: nil
        )
      end

      it 'accepts a :return_metadata option, casuing metadata to be returned in a struct' do
        struct = store_with_metadata.store('x', '1', return_metadata: true)
        expect(struct).to be_a Struct
        expect(struct.to_h).to match a_hash_including(
          value: '1',
          name: nil,
          type: nil
        )
      end
    end

    describe '#values_at' do
      it 'returns an array of structs if :return_metadata is true' do
        store_with_metadata.store('x', '1', metadata: {name: 'test1'})
        store_with_metadata.store('y', '2', metadata: {name: 'test2'})

        structs = store_with_metadata.values_at('x', 'y', 'z', return_metadata: true)
        expect(structs[0..1]).to all be_a Struct
        expect(structs[2]).to be nil
        expect(structs[0..1].map(&:to_h)).to match([
          a_hash_including(value: '1', name: 'test1', type: nil),
          a_hash_including(value: '2', name: 'test2', type: nil)
        ])
      end
    end
  end
end
