describe 'transformer_marshal_hmac', proxy: :Transformer do
  moneta_build do
    Moneta.build do
      use :Transformer, key: :marshal, value: [:marshal, :hmac], secret: 'secret'
      adapter :Memory
    end
  end

  moneta_loader do |value|
    ::Marshal.load(::Moneta::Transformer::Helper.hmacverify(value, 'secret'))
  end

  moneta_specs STANDARD_SPECS.without_persist.with_each_key
end
