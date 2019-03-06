describe 'lock', proxy: :Lock do
  moneta_build do
    Moneta.build do
      use :Lock
      adapter :Memory
    end
  end

  moneta_specs STANDARD_SPECS.without_transform.returnsame.without_persist.with_each_key
end
