require_relative '../../memcached_helper.rb'

describe 'adapter_memcached_native', isolate: true, unstable: defined?(JRUBY_VERSION), retry: 3, adapter: :Memcached do
  # See https://github.com/memcached/memcached/issues/307
  let(:t_res) { 1 }
  let(:min_ttl) { 2 }

  include_context :start_memcached, 11214

  describe 'without default expires' do
    moneta_build do
      Moneta::Adapters::MemcachedNative.new(server: "127.0.0.1:11214")
    end

    moneta_specs ADAPTER_SPECS.with_native_expires
  end

  describe 'with default expires' do
    moneta_build do
      Moneta::Adapters::MemcachedNative.new(server: '127.0.0.1:11214', expires: min_ttl)
    end

    moneta_specs NATIVE_EXPIRY_SPECS.with_default_expires
  end
end
