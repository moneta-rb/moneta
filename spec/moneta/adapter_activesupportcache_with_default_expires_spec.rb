require 'active_support'
require 'active_support/cache/moneta_store'

describe 'adapter_activesupportcache_with_default_expires' do
  shared_examples :adapter_activesupportcache_with_default_expires do
    moneta_build do
      Moneta::Adapters::ActiveSupportCache.new(backend: backend, expires: min_ttl)
    end

    moneta_specs ADAPTER_SPECS.without_concurrent.without_create.with_native_expires.with_default_expires
  end

  context 'using MemoryStore' do
    let(:t_res) { 0.125 }
    let(:min_ttl) { t_res }

    let(:backend) { ActiveSupport::Cache::MemoryStore.new }
    include_examples :adapter_activesupportcache_with_default_expires
  end

  context 'using MemCacheStore' do
    let(:t_res) { 1 }
    let(:min_ttl) { 2 }

    let(:backend) { ActiveSupport::Cache::MemCacheStore.new }
    include_examples :adapter_activesupportcache_with_default_expires
  end

  context 'using RedisCacheStore' do
    let(:t_res) { 1 }
    let(:min_ttl) { t_res }

    let(:backend) { ActiveSupport::Cache::RedisCacheStore.new(url: 'redis:///2') }
    include_examples :adapter_activesupportcache_with_default_expires
  end

  context 'using MonetaStore' do
    let(:t_res) { 0.125 }
    let(:min_ttl) { t_res }

    let(:backend) { ActiveSupport::Cache::MonetaStore.new(store: Moneta.new(:Memory)) }
    include_examples :adapter_activesupportcache_with_default_expires
  end
end
