describe 'adapter_daybreak', adapter: :Daybreak do
  moneta_build do
    Moneta::Adapters::Daybreak.new(file: File.join(tempdir, "adapter_daybreak"))
  end

  moneta_specs ADAPTER_SPECS.without_multiprocess.returnsame.with_each_key
end
