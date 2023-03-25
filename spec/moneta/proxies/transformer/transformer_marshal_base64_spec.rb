describe 'transformer_marshal_base64', proxy: :Transformer do
  moneta_build do

    Moneta.build do
      use :Transformer, key: [:marshal, :base64], value: [:marshal, :base64]
      adapter :Memory
    end
  end

  moneta_loader do |value|
    ::Marshal.load(value.unpack1('m'))
  end

  moneta_specs STANDARD_SPECS.without_persist.with_each_key
end
