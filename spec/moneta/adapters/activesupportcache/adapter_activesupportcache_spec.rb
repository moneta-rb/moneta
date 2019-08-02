require_relative '../memcached_helper.rb'

describe 'adapter_activesupportcache', adapter: :ActiveSupportCache do
  before :all do
    require 'active_support'
    require 'active_support/cache/moneta_store'
  end

  shared_examples :adapter_activesupportcache do
    moneta_build do
      Moneta::Adapters::ActiveSupportCache.new(backend: backend)
    end

    moneta_specs ADAPTER_SPECS.without_concurrent.without_create.with_native_expires
  end

  context 'using MemoryStore' do
    let(:t_res) { 0.125 }
    let(:min_ttl) { t_res }
    use_timecop

    let(:backend) { ActiveSupport::Cache::MemoryStore.new }
    include_examples :adapter_activesupportcache
  end

  context 'using MemCacheStore' do
    let(:t_res) { 1 }
    let(:min_ttl) { 2 }
    use_timecop

    include_context :start_memcached, 11215

    let(:backend) { ActiveSupport::Cache::MemCacheStore.new('127.0.0.1:11215') }
    include_examples :adapter_activesupportcache
  end

  context 'using RedisCacheStore' do
    let(:t_res) { 1 }
    let(:min_ttl) { t_res }
    use_timecop

    let(:backend) { ActiveSupport::Cache::RedisCacheStore.new(url: 'redis:///1') }
    include_examples :adapter_activesupportcache
  end

  context 'using MonetaStore' do
    let(:t_res) { 0.125 }
    let(:min_ttl) { t_res }
    use_timecop

    let(:backend) { ActiveSupport::Cache::MonetaStore.new(store: Moneta.new(:Memory)) }
    include_examples :adapter_activesupportcache
  end
end
