describe 'expires_memory_with_default_expires', isolate: true, proxy: :Expires do
  let(:t_res) { 1 }
  let(:min_ttl) { t_res }

  use_timecop

  moneta_build do
    min_ttl = self.min_ttl
    Moneta.build do
      use :Expires, expires: min_ttl
      adapter :Memory
    end
  end

  moneta_specs DEFAULT_EXPIRES_SPECS
end
