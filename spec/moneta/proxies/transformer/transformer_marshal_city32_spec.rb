describe 'transformer_marshal_city32', unsupported: defined?(JRUBY_VERSION), proxy: :Transformer do
  moneta_build do
    Moneta.build do
      use :Transformer, key: [:marshal, :city32], value: :marshal
      adapter :Memory
    end
  end

  moneta_specs STANDARD_SPECS.without_persist
end
