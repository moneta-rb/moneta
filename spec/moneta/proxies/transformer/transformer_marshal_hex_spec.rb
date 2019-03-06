describe 'transformer_marshal_hex', proxy: :Transformer do
  moneta_build do

    Moneta.build do
      use :Transformer, key: [:marshal, :hex], value: [:marshal, :hex]
      adapter :Memory
    end
  end

  moneta_loader do |value|
    ::Marshal.load([value].pack('H*'))
  end

  moneta_specs STANDARD_SPECS.without_persist

  it 'compile transformer class' do
    store.should_not be_nil
    Moneta::Transformer::MarshalHexKeyMarshalHexValue.should_not be_nil
  end
end
