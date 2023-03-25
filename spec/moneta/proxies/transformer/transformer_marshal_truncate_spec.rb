describe 'transformer_marshal_truncate', proxy: :Transformer do
  moneta_build do
    Moneta.build do
      use :Transformer, key: [:marshal, :truncate], value: :marshal, maxlen: 64
      adapter :Memory
    end
  end

  moneta_specs STANDARD_SPECS.without_persist
end
