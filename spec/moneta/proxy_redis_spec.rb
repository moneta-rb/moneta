describe "proxy_redis" do
  moneta_build do
    Moneta.build do
      use :Proxy
      use :Proxy
      adapter :Redis
    end
  end

  moneta_specs ADAPTER_SPECS.with_expires
end
