describe 'metadata_memory', proxy: :Metadata do
  moneta_build do
    Moneta.build do
      use :Metadata, names: %i{test1 test2}
      adapter :Memory
    end
  end

  moneta_specs STANDARD_SPECS.without_transform.without_persist.returnsame.with_each_key
end

