describe 'transformer_marshal_escape', proxy: :Transformer do
  moneta_build do
    Moneta.build do
      use :Transformer, key: [:marshal, :escape], value: [:marshal, :escape]
      adapter :Memory
    end
  end

  moneta_loader do |value|
    ::Marshal.load(::URI.decode_www_form_component(value))
  end

  moneta_specs STANDARD_SPECS.without_persist

  it 'compiles the transformer class' do
    store.should_not be_nil
    Moneta::Transformer::MarshalEscapeKeyMarshalEscapeValue.should_not be_nil
  end
end
