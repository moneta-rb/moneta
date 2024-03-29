describe 'transformer_lzma', unsupported: defined?(JRUBY_VERSION), proxy: :Transformer do
  moneta_build do
    Moneta.build do
      use :Transformer, value: :lzma
      adapter :Memory
    end
  end

  moneta_loader do |value|
    ::LZMA.decompress(value)
  end

  moneta_specs TRANSFORMER_SPECS.stringvalues_only.with_each_key
end
