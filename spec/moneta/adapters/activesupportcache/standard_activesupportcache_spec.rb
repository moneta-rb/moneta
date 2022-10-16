describe 'standard_activesupportcache', adapter: :ActiveSupportCache, broken: ::Gem::Version.new(RUBY_ENGINE_VERSION) >= ::Gem::Version.new('3.0.0') do
  before :context do
    require 'active_support'
  end

  let(:t_res) { 0.1 }
  let(:min_ttl) { 0.1 }

  moneta_store :ActiveSupportCache do
    { backend: ActiveSupport::Cache::MemoryStore.new }
  end

  moneta_specs STANDARD_SPECS.without_create.without_persist.with_native_expires
end
