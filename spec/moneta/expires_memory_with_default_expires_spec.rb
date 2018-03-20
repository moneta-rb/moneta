describe 'expires_memory_with_default_expires' do
  moneta_build do
    Moneta.build do
      use :Expires, expires: 1
      adapter :Memory
    end
  end

  moneta_specs STANDARD_SPECS.without_transform.with_expires.with_default_expires.without_persist.returnsame.with_each_key
end
