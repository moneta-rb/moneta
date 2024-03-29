describe 'transformer_yaml', proxy: :Transformer, broken: ::Gem::Version.new(RUBY_VERSION) >= ::Gem::Version.new('3.1.0') do
  moneta_build do
    Moneta.build do
      use :Transformer, key: :yaml, value: :yaml
      adapter :Memory
    end
  end

  moneta_loader do |value|
    ::YAML.load(value)
  end

  moneta_specs TRANSFORMER_SPECS
end
