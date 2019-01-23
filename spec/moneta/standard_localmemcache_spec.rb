describe 'standard_localmemcache', broken: true do
  moneta_store :LocalMemCache do
    {file: File.join(tempdir, "simple_localmemcache")}
  end

  moneta_specs STANDARD_SPECS.without_increment.without_create
end
