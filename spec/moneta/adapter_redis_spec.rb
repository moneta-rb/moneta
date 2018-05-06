describe 'adapter_redis' do
  let(:t_res){ 1 }
  let(:min_ttl){ t_res }

  moneta_build do
    Moneta::Adapters::Redis.new(db: 6)
  end

  moneta_specs ADAPTER_SPECS.with_native_expires
end
