describe 'standard_tdb', unsupported: defined?(JRUBY_VERSION), adapter: :TDB do
  moneta_store :TDB do
    {file: File.join(tempdir, "simple_tdb")}
  end

  moneta_specs STANDARD_SPECS.without_multiprocess
end
