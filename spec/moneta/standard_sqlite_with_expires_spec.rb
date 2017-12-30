describe 'standard_sqlite_with_expires' do
  moneta_store :Sqlite do
    {file: File.join(tempdir, "simple_sqlite_with_expires"), expires: true}
  end
  
  moneta_specs STANDARD_SPECS.with_expires.without_concurrent
end
