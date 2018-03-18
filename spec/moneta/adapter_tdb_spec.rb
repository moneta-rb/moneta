describe 'adapter_tdb' do
  moneta_build do
    Moneta::Adapters::TDB.new(file: File.join(tempdir, "adapter_tdb"))
  end

  moneta_specs ADAPTER_SPECS.with_each_key.without_multiprocess
end
