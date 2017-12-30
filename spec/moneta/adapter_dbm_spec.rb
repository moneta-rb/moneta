describe 'adapter_dbm' do
  moneta_build do
    Moneta::Adapters::DBM.new(file: File.join(tempdir, "adapter_dbm"))
  end

  moneta_specs ADAPTER_SPECS.without_multiprocess
end
