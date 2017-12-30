describe 'standard_dbm' do
  moneta_store :DBM do
    {file: File.join(tempdir, "simple_dbm")}
  end

  moneta_specs STANDARD_SPECS.without_multiprocess
end
