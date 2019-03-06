describe 'transformer_php', proxy: :Transformer do
  moneta_build do
    Moneta.build do
      use :Transformer, key: :php, value: :php
      adapter :Memory
    end
  end

  moneta_loader do |value|
    ::PHP.unserialize(value)
  end

  moneta_specs TRANSFORMER_SPECS.simplekeys_only.simplevalues_only

  it 'compile transformer class' do
    store.should_not be_nil
    Moneta::Transformer::PhpKeyPhpValue.should_not be_nil
  end
end
