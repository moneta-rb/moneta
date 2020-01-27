describe 'transformer_marshal_md5_spread', proxy: :Transformer do
  moneta_build do
    Moneta.build do
      use :Transformer, key: [:marshal, :md5, :spread], value: :marshal
      adapter :Memory
    end
  end

  moneta_specs STANDARD_SPECS.without_persist

  it 'compile transformer class' do
    store.should_not be_nil
    Moneta::Transformer::MarshalMd5SpreadKeyMarshalValue.should_not be_nil
  end
end
