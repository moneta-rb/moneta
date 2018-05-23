describe 'adapter_redis_with_default_expires' do
  let(:t_res){ 1 }
  let(:min_ttl){ t_res }

  moneta_build do
    Moneta::Adapters::Redis.new(db: 7, expires: min_ttl)
  end

  moneta_specs ADAPTER_SPECS.with_native_expires.with_default_expires
end
