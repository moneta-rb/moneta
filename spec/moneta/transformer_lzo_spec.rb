describe 'transformer_lzo' do
  moneta_build do
    Moneta.build do
      use :Transformer, value: :lzo
      adapter :Memory
    end
  end

  moneta_loader do |value|
    ::LZO.decompress(value)
  end

  moneta_specs TRANSFORMER_SPECS.stringvalues_only

  it 'compile transformer class' do
    store.should_not be_nil
    Moneta::Transformer::LzoValue.should_not be_nil
  end
end
