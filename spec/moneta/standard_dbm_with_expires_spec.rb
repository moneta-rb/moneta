describe 'standard_dbm_with_expires' do
  moneta_store :DBM do
    { file: File.join(tempdir, "simple_dbm_with_expires"),
      expires: true }
  end

  moneta_specs STANDARD_SPECS.without_multiprocess.with_expires
end
