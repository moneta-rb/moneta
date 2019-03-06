describe 'transformer_bzip2', proxy: :Transformer do
  moneta_build do
    Moneta.build do
      use :Transformer, value: :bzip2
      adapter :Memory
    end
  end

  moneta_loader do |value|
    ::RBzip2.default_adapter::Decompressor.new(::StringIO.new(value)).read
  end

  moneta_specs TRANSFORMER_SPECS.stringvalues_only.with_each_key

  it 'compile transformer class' do
    store.should_not be_nil
    Moneta::Transformer::Bzip2Value.should_not be_nil
  end
end
