describe 'standard_sdbm', unsupported: defined?(JRUBY_VERSION), adapter: :SDBM do
  moneta_store :SDBM do
    {file: File.join(tempdir, "simple_sdbm")}
  end

  moneta_specs STANDARD_SPECS.without_multiprocess.without_large
end
