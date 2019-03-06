describe 'adapter_tokyotyrant', isolate: true, adapter: :TokyoTyrant do
  moneta_build do
    Moneta::Adapters::TokyoTyrant.new
  end

  moneta_specs ADAPTER_SPECS
end
