describe 'expires_memory_with_default_expires' do
  let(:t_res){ 1 }
  let(:min_ttl){ t_res }

  moneta_build do
    Moneta.build do
      use :Expires, expires: min_ttl
      adapter :Memory
    end
  end

  moneta_specs STANDARD_SPECS.without_transform.with_expires.with_default_expires.without_persist.returnsame.with_each_key
end
