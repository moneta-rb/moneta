describe 'standard_localmemcache_with_expires' do
  moneta_store :LocalMemCache do
    {file: File.join(tempdir, "simple_localmemcache_with_expires"), expires: true}
  end

  moneta_specs STANDARD_SPECS.without_increment.without_create.with_expires
end
