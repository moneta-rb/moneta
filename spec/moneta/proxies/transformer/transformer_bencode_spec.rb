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

  moneta_specs TRANSFORMER_SPECS.simplekeys_only.simplevalues_only.with_each_key
end
