describe 'transformer_value_marshal', proxy: :Transformer do
  moneta_build do
    Moneta.build do
      use :Transformer, value: :marshal
      adapter :Memory
    end
  end

  moneta_loader do |value|
    ::Marshal.load(value)
  end

  moneta_specs TRANSFORMER_SPECS.with_each_key

  it 'compile transformer class' do
    store.should_not be_nil
    Moneta::Transformer::MarshalValue.should_not be_nil
  end
end
