describe 'adapter_sdbm' do
  moneta_build do
    Moneta::Adapters::SDBM.new(file: File.join(tempdir, "adapter_sdbm"))
  end

  moneta_specs ADAPTER_SPECS.without_multiprocess.without_large.with_each_key
end
