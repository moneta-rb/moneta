describe 'transformer_marshal_qp', proxy: :Transformer do
  moneta_build do

    Moneta.build do
      use :Transformer, key: [:marshal, :qp], value: [:marshal, :qp]
      adapter :Memory
    end
  end

  moneta_loader do |value|
    ::Marshal.load(value.unpack('M').first)
  end

  moneta_specs STANDARD_SPECS.without_persist

  it 'compile transformer class' do
    store.should_not be_nil
    Moneta::Transformer::MarshalQpKeyMarshalQpValue.should_not be_nil
  end
end
