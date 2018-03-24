describe 'adapter_redis' do
  moneta_build do
    Moneta::Adapters::Redis.new
  end

  moneta_specs ADAPTER_SPECS.with_each_key.with_native_expires
end
