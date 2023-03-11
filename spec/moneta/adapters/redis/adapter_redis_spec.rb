describe 'adapter_redis', adapter: :Redis do
  let(:t_res) { 0.125 }
  let(:min_ttl) { t_res }

  describe 'without default expiry' do
    moneta_build do
      Moneta::Adapters::Redis.new(host: redis_host, port: redis_port, db: 6)
    end

    moneta_specs ADAPTER_SPECS.with_each_key.with_native_expires
  end

  describe 'with default expiry' do
    moneta_build do
      Moneta::Adapters::Redis.new(host: redis_host, port: redis_port, db: 6, expires: min_ttl)
    end

    moneta_specs DEFAULT_EXPIRES_SPECS
  end
end
