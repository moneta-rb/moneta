describe 'transformer_msgpack', proxy: :Transformer do
  moneta_build do
    Moneta.build do
      use :Transformer, key: :msgpack, value: :msgpack
      adapter :Memory
    end
  end

  moneta_loader do |value|
    ::MessagePack.unpack(value)
  end

  moneta_specs TRANSFORMER_SPECS.simplekeys_only.simplevalues_only

  it 'compile transformer class' do
    store.should_not be_nil
    Moneta::Transformer::MsgpackKeyMsgpackValue.should_not be_nil
  end
end
