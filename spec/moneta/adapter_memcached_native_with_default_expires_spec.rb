describe 'adapter_memcached_native_with_default_expires', isolate: true, unstable: defined?(JRUBY_VERSION) do
  # See https://github.com/memcached/memcached/issues/307
  let(:t_res) { 1 }
  let(:min_ttl) { 2 }

  moneta_build do
    Moneta::Adapters::MemcachedNative.new(expires: min_ttl)
  end

  moneta_specs ADAPTER_SPECS.with_native_expires.with_default_expires
end
