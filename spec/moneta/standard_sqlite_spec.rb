describe 'standard_sqlite' do
  moneta_store :Sqlite do
    {file: File.join(tempdir, "simple_sqlite")}
  end

  moneta_specs STANDARD_SPECS.without_concurrent
end
