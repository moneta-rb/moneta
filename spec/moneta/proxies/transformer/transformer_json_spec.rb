describe 'transformer_json', proxy: :Transformer do
  moneta_build do
    Moneta.build do
      use :Transformer, key: :json, value: :json
      adapter :Memory
    end
  end

  moneta_loader do |value|
    ::MultiJson.load(value)
  end

  moneta_specs TRANSFORMER_SPECS.simplekeys_only.simplevalues_only

  it 'compile transformer class' do
    store.should_not be_nil
    Moneta::Transformer::JsonKeyJsonValue.should_not be_nil
  end
end
