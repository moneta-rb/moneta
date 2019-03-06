describe 'standard_localmemcache_with_expires', unsupported: defined?(JRUBY_VERSION), adapter: :LocalMemCache do
  let(:t_res) { 0.125 }
  let(:min_ttl) { t_res }
  use_timecop

  moneta_store :LocalMemCache do
    {file: File.join(tempdir, "simple_localmemcache_with_expires"), expires: true}
  end

  moneta_specs STANDARD_SPECS.without_increment.without_create.with_expires
end
