describe "proxy_redis", proxy: :Proxy do
  let(:t_res) { 0.125 }
  let(:min_ttl) { t_res }

  moneta_build do
    Moneta.build do
      use :Proxy
      adapter :Redis, db: 5
    end
  end

  moneta_specs ADAPTER_SPECS.with_each_key.with_expires
end
