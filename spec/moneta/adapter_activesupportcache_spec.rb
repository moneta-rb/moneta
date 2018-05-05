require 'active_support'
require 'active_support/cache/moneta_store'

describe 'adapter_activesupportcache' do
  shared_examples :adapter_activesupportcache do
    moneta_build do
      Moneta::Adapters::ActiveSupportCache.new(backend: backend)
    end

    moneta_specs ADAPTER_SPECS.without_create.without_concurrent
  end

  context 'using MemoryStore' do
    let(:backend) { ActiveSupport::Cache::MemoryStore.new }
    include_examples :adapter_activesupportcache
  end

  context 'using MemCacheStore' do
    let(:backend) { ActiveSupport::Cache::MemCacheStore.new }
    include_examples :adapter_activesupportcache
  end

  context 'using RedisCacheStore' do
    let(:backend) { ActiveSupport::Cache::RedisCacheStore.new }
    include_examples :adapter_activesupportcache
  end

  context 'using MonetaStore' do
    let(:backend) { ActiveSupport::Cache::MonetaStore.new(store: Moneta.new(:Memory)) }
    include_examples :adapter_activesupportcache
  end
end
