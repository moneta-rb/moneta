describe 'transformer_ox', unsupported: defined?(JRUBY_VERSION), proxy: :Transformer do
  moneta_build do
    Moneta.build do
      use :Transformer, key: :ox, value: :ox
      adapter :Memory
    end
  end

  moneta_loader do |value|
    ::Ox.parse_obj(value)
  end

  moneta_specs TRANSFORMER_SPECS.without_keys_or_values(:binary, :float)
end
