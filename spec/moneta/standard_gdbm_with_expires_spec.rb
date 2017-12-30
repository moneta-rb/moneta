describe 'standard_gdbm_with_expires' do
  moneta_store :GDBM do
    {file: File.join(tempdir, "simple_gdbm_with_expires"), expires: true}
  end
  
  moneta_specs STANDARD_SPECS.without_multiprocess.with_expires
end
