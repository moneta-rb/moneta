describe 'transformer_marshal_qp', proxy: :Transformer do
  moneta_build do
    Moneta.build do
      use :Transformer, key: [:marshal, :qp], value: [:marshal, :qp]
      adapter :Memory
    end
  end

  moneta_loader do |value|
    ::Marshal.load(value.unpack1('M'))
  end

  moneta_specs STANDARD_SPECS.without_persist.with_each_key
end
