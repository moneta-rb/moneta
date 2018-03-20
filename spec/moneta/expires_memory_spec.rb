describe 'expires_memory' do
  moneta_build do
    Moneta.build do
      use :Expires
      adapter :Memory
    end
  end

  moneta_specs STANDARD_SPECS.without_transform.with_expires.without_persist.returnsame.with_each_key
end
