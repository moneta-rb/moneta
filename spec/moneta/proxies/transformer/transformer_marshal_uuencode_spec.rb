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

  moneta_specs STANDARD_SPECS.without_persist
end
