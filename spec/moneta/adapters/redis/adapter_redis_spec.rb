describe 'adapter_redis', adapter: :Redis do
  let(:t_res) { 0.125 }
  let(:min_ttl) { t_res }

  moneta_build do
    Moneta::Adapters::Redis.new(db: 6)
  end

  moneta_specs ADAPTER_SPECS.with_each_key.with_native_expires
end
