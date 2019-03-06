describe 'transformer_bert', unsupported: defined?(JRUBY_VERSION), proxy: :Transformer do
  moneta_build do
    Moneta.build do
      use :Transformer, key: :bert, value: :bert
      adapter :Memory
    end
  end

  moneta_loader do |value|
    ::BERT.decode(value)
  end
  
  moneta_specs TRANSFORMER_SPECS.simplekeys_only.simplevalues_only
  
  it 'compile transformer class' do
    store.should_not be_nil
    Moneta::Transformer::BertKeyBertValue.should_not be_nil
  end
end
