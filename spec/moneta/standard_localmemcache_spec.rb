describe 'standard_localmemcache', unsupported: defined?(JRUBY_VERSION) do
  moneta_store :LocalMemCache do
    {file: File.join(tempdir, "simple_localmemcache")}
  end

  moneta_specs STANDARD_SPECS.without_increment.without_create
end
