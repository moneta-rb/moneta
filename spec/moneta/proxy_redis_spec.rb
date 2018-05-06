describe "proxy_redis" do
  let(:t_res){ 1 }
  let(:min_ttl){ t_res }

  moneta_build do
    Moneta.build do
      use :Proxy
      use :Proxy
      adapter :Redis, db: 5
    end
  end

  moneta_specs ADAPTER_SPECS.with_expires
end
