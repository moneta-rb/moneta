describe 'standard_memory_with_prefix', adapter: :Memory do
  moneta_store :Memory, { prefix: "moneta" }
  moneta_specs STANDARD_SPECS.without_persist.with_each_key

  context 'with keys from no prefix' do
    before(:each) do
      store.adapter.adapter.backend['no_prefix'] = 'hidden'
    end

    after(:each) do
      expect(store.adapter.adapter.backend.keys).to include('no_prefix')
    end

    include_examples :each_key
  end

  context 'with keys from other prefixes' do
    before do
      backend = store.adapter.adapter.backend
      @alternative_store ||= Moneta.build do
        use :Transformer, key: [:marshal, :prefix], value: :marshal, prefix: 'alternative_'
        adapter :Memory, backend: backend
      end
      expect(@alternative_store).to be_a(Moneta::Transformer::MarshalPrefixKeyMarshalValue)
    end
    let(:alternative) { @alternative_store }

    before(:each) do
      alternative.store('with_prefix_key', 'hidden')
    end

    after(:each) do
      expect(store.adapter.adapter.backend.keys).to include('alternative_with_prefix_key')
      expect(alternative.each_key.to_a).to eq(['with_prefix_key'])
      expect(alternative['with_prefix_key']).to eq('hidden')
    end

    include_examples :each_key
  end

end
