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

  moneta_specs STANDARD_SPECS.without_persist.with_each_key
end
