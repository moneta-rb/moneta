describe 'standard_memory_with_prefix', adapter: :Memory do
  moneta_store :Memory, {prefix: "moneta"}
  moneta_specs STANDARD_SPECS.without_persist.with_each_key

  context 'with keys with no prefix' do
    before(:each) do
      store.adapter.adapter.backend['no_prefix'] = 'hidden'
    end

    after(:each) do
      expect(store.adapter.adapter.backend.keys).to include('no_prefix')
    end

    include_examples :each_key
  end
end
