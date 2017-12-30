describe 'adapter_redis_with_default_expires' do
  moneta_build do
    Moneta::Adapters::Redis.new(expires: 1)
  end

  moneta_specs ADAPTER_SPECS.with_native_expires.with_default_expires
end
