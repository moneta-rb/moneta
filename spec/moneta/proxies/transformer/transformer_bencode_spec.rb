describe 'transformer_bencode', proxy: :Transformer do
  moneta_build do
    Moneta.build do
      use :Transformer, key: :bencode, value: :bencode
      adapter :Memory
    end
  end

  moneta_loader do |value|
    ::BEncode.load(value)
  end

  moneta_specs TRANSFORMER_SPECS.simplekeys_only.simplevalues_only

  it 'compile transformer class' do
    store.should_not be_nil
    Moneta::Transformer::BencodeKeyBencodeValue.should_not be_nil
  end
end
