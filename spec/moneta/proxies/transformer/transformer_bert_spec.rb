describe 'transformer_bert', unsupported: defined?(JRUBY_VERSION), broken: ::Gem::Version.new(RUBY_VERSION) >= ::Gem::Version.new('3.2.0'), proxy: :Transformer do
  moneta_build do
    Moneta.build do
      use :Transformer, key: :bert, value: :bert
      adapter :Memory
    end
  end

  moneta_loader do |value|
    ::BERT.decode(value)
  end

  moneta_specs TRANSFORMER_SPECS.simplekeys_only.simplevalues_only.with_each_key
end
