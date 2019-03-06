describe 'transformer_marshal_prefix', proxy: :Transformer do
  moneta_build do
    Moneta.build do
      use :Transformer, key: [:marshal, :prefix], value: :marshal, prefix: 'moneta'
      adapter :Memory
    end
  end

  moneta_specs STANDARD_SPECS.without_persist

  it 'compile transformer class' do
    store.should_not be_nil
    Moneta::Transformer::MarshalPrefixKeyMarshalValue.should_not be_nil
  end
end
