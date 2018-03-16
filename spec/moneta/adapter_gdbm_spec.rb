describe 'adapter_gdbm' do
  moneta_build do
    Moneta::Adapters::GDBM.new(file: File.join(tempdir, "adapter_gdbm"))
  end

  moneta_specs ADAPTER_SPECS.with_each_key.without_multiprocess
end
