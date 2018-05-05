require 'active_support'
require 'active_support/cache/moneta_store'

describe 'adapter_activesupport' do
  shared_examples :adapter_activesupport do
    moneta_build do
      Moneta::Adapters::ActiveSupport.new(backend: backend)
    end

    moneta_specs ADAPTER_SPECS.without_create.without_concurrent
  end

  context 'using MemoryStore' do
    let(:backend) { ActiveSupport::Cache::MemoryStore.new }
    include_examples :adapter_activesupport
  end

  context 'using MemCacheStore' do
    let(:backend) { ActiveSupport::Cache::MemCacheStore.new }
    include_examples :adapter_activesupport
  end

  context 'using MonetaStore' do
    let(:backend) { ActiveSupport::Cache::MonetaStore.new(store: Moneta.new(:Memory)) }
    include_examples :adapter_activesupport
  end
end
