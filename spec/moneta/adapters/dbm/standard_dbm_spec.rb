describe 'standard_dbm', unsupported: defined?(JRUBY_VERSION), adapter: :DBM do
  moneta_store :DBM do
    {file: File.join(tempdir, "simple_dbm")}
  end

  moneta_specs STANDARD_SPECS.without_multiprocess
end
