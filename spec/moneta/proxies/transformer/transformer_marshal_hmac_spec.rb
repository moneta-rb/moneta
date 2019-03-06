describe 'transformer_marshal_hmac', proxy: :Transformer do
  moneta_build do
    Moneta.build do
      use :Transformer, key: :marshal, value: [:marshal, :hmac], secret: 'secret'
      adapter :Memory
    end
  end

  moneta_loader do |value|
    ::Marshal.load(::Moneta::Transformer::Helper.hmacverify(value, 'secret'))
  end

  moneta_specs STANDARD_SPECS.without_persist

  it 'compile transformer class' do
    store.should_not be_nil
    Moneta::Transformer::MarshalKeyMarshalHmacValue.should_not be_nil
  end
end
