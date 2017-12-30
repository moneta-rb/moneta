describe 'transformer_lz4' do
  moneta_build do
    Moneta.build do
      use :Transformer, value: :lz4
      adapter :Memory
    end
  end

  moneta_loader do |value|
    ::LZ4.uncompress(value)
  end

  moneta_specs TRANSFORMER_SPECS.stringvalues_only

  it 'compile transformer class' do
    store.should_not be_nil
    Moneta::Transformer::Lz4Value.should_not be_nil
  end
end
