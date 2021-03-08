require_relative '../../memcached_helper.rb'

describe 'adapter_memcached_dalli', retry: 3, adapter: :Memcached do
  # See https://github.com/memcached/memcached/issues/307
  let(:t_res) { 1 }
  let(:min_ttl) { 2 }

  include_context :start_memcached, 11212

  describe 'without default expires' do
    moneta_build do
      Moneta::Adapters::MemcachedDalli.new(server: "127.0.0.1:11212")
    end

    moneta_specs ADAPTER_SPECS.with_native_expires
  end

  describe 'with default expires' do
    moneta_build do
      Moneta::Adapters::MemcachedDalli.new(server: '127.0.0.1:11212', expires: min_ttl)
    end

    moneta_specs NATIVE_EXPIRY_SPECS.with_default_expires
  end
end
