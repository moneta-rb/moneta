describe 'transformer_tnet', proxy: :Transformer do
  moneta_build do
    Moneta.build do
      use :Transformer, key: :tnet, value: :tnet
      adapter :Memory
    end
  end

  moneta_loader do |value|
    ::TNetstring.parse(value).first
  end

  moneta_specs TRANSFORMER_SPECS.simplekeys_only.simplevalues_only

  it 'compile transformer class' do
    store.should_not be_nil
    Moneta::Transformer::TnetKeyTnetValue.should_not be_nil
  end
end
