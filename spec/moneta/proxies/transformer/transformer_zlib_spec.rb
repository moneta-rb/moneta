describe 'transformer_zlib', proxy: :Transformer do
  moneta_build do
    Moneta.build do
      use :Transformer, value: :zlib
      adapter :Memory
    end
  end

  moneta_loader do |value|
    ::Zlib::Inflate.inflate(value)
  end

  moneta_specs TRANSFORMER_SPECS.stringvalues_only.with_each_key

  it 'compile transformer class' do
    store.should_not be_nil
    Moneta::Transformer::ZlibValue.should_not be_nil
  end
end
