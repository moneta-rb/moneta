# Currently broken in JRuby 9.3 - see https://github.com/jruby/jruby/issues/6941

describe 'transformer_bson', proxy: :Transformer, broken: defined?(JRUBY_VERSION) && ::Gem::Version.new(JRUBY_VERSION) >= ::Gem::Version.new('9.3.0.0') do
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

  moneta_specs TRANSFORMER_SPECS.simplekeys_only.simplevalues_only.with_each_key

  it 'compile transformer class' do
    store.should_not be_nil
    Moneta::Transformer::BsonKeyBsonValue.should_not be_nil
  end
end
