describe 'transformer_lzo', unsupported: defined?(JRUBY_VERSION), proxy: :Transformer do
  moneta_build do
    Moneta.build do
      use :Transformer, value: :lzo
      adapter :Memory
    end
  end

  moneta_loader do |value|
    ::LZO.decompress(value)
  end

  moneta_specs TRANSFORMER_SPECS.stringvalues_only.with_each_key
end
