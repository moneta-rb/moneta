describe 'adapter_tokyotyrant' do
  moneta_build do
    Moneta::Adapters::TokyoTyrant.new
  end

  moneta_specs ADAPTER_SPECS
end
