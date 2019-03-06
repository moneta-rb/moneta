describe 'adapter_redis_with_default_expires', isolate: true, adapter: :Redis do
  let(:t_res) { 0.125 }
  let(:min_ttl) { t_res }

  moneta_build do
    Moneta::Adapters::Redis.new(db: 7, expires: min_ttl)
  end

  moneta_specs ADAPTER_SPECS.with_each_key.with_native_expires.with_default_expires
end
