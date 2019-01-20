describe 'adapter_localmemcache', unstable: true do
  moneta_build do
    Moneta::Adapters::LocalMemCache.new(file: File.join(tempdir, "adapter_localmemcache"))
  end

  moneta_specs ADAPTER_SPECS.without_increment.without_create
end
