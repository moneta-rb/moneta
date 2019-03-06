describe 'adapter_cookie', adapter: :Cookie do
  moneta_build do
    Moneta::Adapters::Cookie.new
  end

  moneta_specs ADAPTER_SPECS.with_each_key.without_persist.returnsame
end
