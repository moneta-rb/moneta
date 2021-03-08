describe 'standard_sqlite', unsupported: defined?(JRUBY_VERSION), adapter: :Sqlite, sqlite: true do
  moneta_store :Sqlite do
    {file: File.join(tempdir, "standard_sqlite")}
  end

  moneta_specs STANDARD_SPECS.without_concurrent.with_each_key
end
