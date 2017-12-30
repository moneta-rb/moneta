describe 'standard_sdbm' do
  moneta_store :SDBM do
    {file: File.join(tempdir, "simple_sdbm")}
  end

  moneta_specs STANDARD_SPECS.without_multiprocess.without_large
end
