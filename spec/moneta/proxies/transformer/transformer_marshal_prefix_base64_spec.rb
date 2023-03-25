describe 'transformer_marshal_prefix_base64', proxy: :Transformer do
  moneta_build do

    Moneta.build do
      use :Transformer, key: [:marshal, :prefix, :base64], value: [:marshal, :base64], prefix: 'moneta'
      adapter :Memory
    end
  end

  moneta_loader do |value|
    ::Marshal.load(value.unpack1('m'))
  end

  moneta_specs STANDARD_SPECS.without_persist.with_each_key

  context 'with keys with no prefix' do
    before(:each) do
      store.adapter.backend['no_prefix'] = 'hidden'
    end

    after(:each) do
      expect(store.adapter.backend.keys).to include('no_prefix')
    end

    include_examples :each_key
  end

end
