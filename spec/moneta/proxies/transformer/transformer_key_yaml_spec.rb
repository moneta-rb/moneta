describe 'transformer_key_yaml', proxy: :Transformer do
  moneta_build do
    Moneta.build do
      use :Transformer, key: :yaml
      adapter :Memory
    end
  end

  moneta_loader{ |value| value }

  moneta_specs TRANSFORMER_SPECS.returnsame
end
