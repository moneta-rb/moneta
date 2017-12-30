describe "proxy_expires_memory" do
  moneta_build do
    Moneta.build do
      use :Proxy
      use :Expires
      use :Proxy
      adapter :Memory
    end
  end

  moneta_specs STANDARD_SPECS.without_transform.with_expires.returnsame.without_persist
end
