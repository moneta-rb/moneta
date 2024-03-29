describe 'transformer_lz4', unsupported: defined?(JRUBY_VERSION), proxy: :Transformer do
  moneta_build do
    Moneta.build do
      use :Transformer, value: :lz4
      adapter :Memory
    end
  end

  moneta_loader do |value|
    ::LZ4.uncompress(value)
  end

  moneta_specs TRANSFORMER_SPECS.stringvalues_only.with_each_key
end
