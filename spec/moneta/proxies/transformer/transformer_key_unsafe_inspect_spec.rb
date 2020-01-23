describe 'transformer_key_unsafe_inspect', proxy: :Transformer do
  moneta_build do
    Moneta.build do
      use :Transformer, key: :unsafe_inspect
      adapter :Memory
    end
  end

  moneta_loader{ |value| value }

  moneta_specs TRANSFORMER_SPECS.returnsame.simplekeys_only.with_each_key

  it 'compile transformer class' do
    store.should_not be_nil
    Moneta::Transformer::UnsafeInspectKey.should_not be_nil
  end
end
