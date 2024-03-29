describe 'transformer_snappy', unstable: defined?(JRUBY_VERSION), proxy: :Transformer do
  moneta_build do
    Moneta.build do
      use :Transformer, value: :snappy
      adapter :Memory
    end
  end

  moneta_loader do |value|
    ::Snappy.inflate(value)
  end

  moneta_specs TRANSFORMER_SPECS.stringvalues_only.with_each_key
end
