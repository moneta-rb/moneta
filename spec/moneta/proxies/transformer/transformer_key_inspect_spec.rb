describe 'transformer_key_inspect', proxy: :Transformer do
  moneta_build do
    Moneta.build do
      use :Transformer, key: :inspect
      adapter :Memory
    end
  end

  moneta_loader{ |value| value }

  moneta_specs TRANSFORMER_SPECS.returnsame.simplekeys_only
end
