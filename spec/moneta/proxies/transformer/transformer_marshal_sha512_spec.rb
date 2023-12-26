describe 'transformer_marshal_sha512', proxy: :Transformer do
  moneta_build do
    Moneta.build do
      use :Transformer, key: [:marshal, :sha512], value: :marshal
      adapter :Memory
    end
  end

  moneta_specs STANDARD_SPECS.without_persist
end
