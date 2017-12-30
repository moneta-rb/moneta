describe 'adapter_cookie' do
  moneta_build do
    Moneta::Adapters::Cookie.new
  end

  moneta_specs ADAPTER_SPECS.without_persist.returnsame
end
