describe 'standard_sdbm_with_expires' do
  moneta_store :SDBM do
    {file: File.join(tempdir, "simple_sdbm_with_expires"), expires: true}
  end

  moneta_specs STANDARD_SPECS.without_multiprocess.with_expires.without_large
end
