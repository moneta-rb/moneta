describe 'standard_sqlite', unsupported: defined?(JRUBY_VERSION), adapter: :Sqlite do
  moneta_store :Sqlite do
    {file: File.join(tempdir, "standard_sqlite")}
  end

  moneta_specs STANDARD_SPECS.without_concurrent
end
