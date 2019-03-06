describe 'transformer_bson', proxy: :Transformer do
  moneta_build do
    Moneta.build do
      use :Transformer, key: :bson, value: :bson
      adapter :Memory
    end
  end

  moneta_loader do |value|
    if ::BSON::VERSION >= '4.0.0'
      ::BSON::Document.from_bson(::BSON::ByteBuffer.new(value))['v']
    else
      ::BSON::Document.from_bson(::StringIO.new(value))['v']
    end
  end

  moneta_specs TRANSFORMER_SPECS.simplekeys_only.simplevalues_only
  
  it 'compile transformer class' do
    store.should_not be_nil
    Moneta::Transformer::BsonKeyBsonValue.should_not be_nil
  end
end
