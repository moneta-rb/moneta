describe 'transformer_value_yaml', proxy: :Transformer do
  moneta_build do
    Moneta.build do
      use :Transformer, value: :yaml
      adapter :Memory
    end
  end

  moneta_loader do |value|
    ::YAML.load(value)
  end

  moneta_specs TRANSFORMER_SPECS.with_each_key

  it 'compile transformer class' do
    store.should_not be_nil
    Moneta::Transformer::YamlValue.should_not be_nil
  end
end
