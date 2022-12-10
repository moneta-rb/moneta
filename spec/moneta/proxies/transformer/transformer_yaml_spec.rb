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

  moneta_specs TRANSFORMER_SPECS.with_each_key

  it 'compile transformer class' do
    store.should_not be_nil
    Moneta::Transformer::YamlKeyYamlValue.should_not be_nil
  end
end
