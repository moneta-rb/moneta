describe "proxy_expires_memory", isolate: true, proxy: :Proxy do
  let(:t_res) { 0.125 }
  let(:min_ttl) { t_res }
  use_timecop
  
  moneta_build do
    Moneta.build do
      use :Proxy
      use :Expires
      use :Proxy
      adapter :Memory
    end
  end

  moneta_specs STANDARD_SPECS.without_transform.with_expires.returnsame.without_persist.with_each_key
end
