describe 'transformer_key_marshal', proxy: :Transformer do
  moneta_build do
    Moneta.build do
      use :Transformer, key: :marshal
      adapter :Memory
    end
  end

  moneta_loader{ |value| value }

  moneta_specs TRANSFORMER_SPECS.returnsame

  it 'compile transformer class' do
    store.should_not be_nil
    Moneta::Transformer::MarshalKey.should_not be_nil
  end
end
