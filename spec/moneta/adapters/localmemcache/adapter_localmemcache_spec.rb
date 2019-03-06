describe 'adapter_localmemcache', unsupported: defined?(JRUBY_VERSION), adapter: :LocalMemCache do
  moneta_build do
    Moneta::Adapters::LocalMemCache.new(file: File.join(tempdir, "adapter_localmemcache"))
  end

  moneta_specs ADAPTER_SPECS.without_increment.without_create
end
