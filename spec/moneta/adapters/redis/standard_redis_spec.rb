describe 'standard_redis', adapter: :Redis do
  let(:t_res) { 0.125 }
  let(:min_ttl) { t_res }

  moneta_store :Redis do
    {
      db: 4,
      host: redis_host,
      port: redis_port
    }
  end

  moneta_specs STANDARD_SPECS.with_native_expires
end
