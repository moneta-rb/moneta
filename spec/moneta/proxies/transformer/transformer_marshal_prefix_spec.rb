describe 'transformer_marshal_prefix', proxy: :Transformer do
  moneta_build do
    Moneta.build do
      use :Transformer, key: [:marshal, :prefix], value: :marshal, prefix: 'moneta', serialize_keys_unless_string: false
      adapter :Memory
    end
  end

  moneta_specs STANDARD_SPECS.without_persist.with_each_key

  context 'sharing the backend with a store without the prefix' do
    let :other_store do
      ::Moneta::Adapters::Memory.new(backend: store.adapter.backend)
    end

    it "doesn't include unprefixed keys in calls to #each_key" do
      store['x'] = 1
      other_store['x'] = 2
      expect { |b| other_store.each_key(&b) }.to yield_successive_args(a_string_starting_with('moneta'), 'x')
      expect { |b| store.each_key(&b) }.to yield_with_args('x')
    end
  end

  context 'sharing the backend with a store with a distinct prefix' do
    let(:backend) { store.adapter.backend }
    let :other_store do
      backend = self.backend
      Moneta.build do
        use :Transformer, key: [:marshal, :prefix], value: :marshal, prefix: 'alternative', serialize_keys_unless_string: false
        adapter :Memory, backend: backend
      end
    end

    it "is not possible for either store to see the other's keys" do
      store['x'] = 1
      other_store['y'] = 2
      expect { |b| backend.each_key(&b) }.to yield_successive_args(a_string_starting_with('moneta'), a_string_starting_with('alternative'))
      expect { |b| store.each_key(&b) }.to yield_with_args('x')
      expect { |b| other_store.each_key(&b) }.to yield_with_args('y')
    end
  end
end
