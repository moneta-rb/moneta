describe 'transformer_marshal_uuencode', proxy: :Transformer do
  moneta_build do
    Moneta.build do
      use :Transformer, key: [:marshal, :uuencode], value: [:marshal, :uuencode]
      adapter :Memory
    end
  end

  moneta_loader do |value|
    ::Marshal.load(value.unpack1('u'))
  end

  moneta_specs STANDARD_SPECS.without_persist.with_each_key

  it 'compile transformer class' do
    store.should_not be_nil
    Moneta::Transformer::MarshalUuencodeKeyMarshalUuencodeValue.should_not be_nil
  end
end
