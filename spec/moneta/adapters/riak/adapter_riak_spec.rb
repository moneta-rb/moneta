describe 'adapter_riak', isolate: true, unstable: true, adapter: :Riak do
  before :all do
    require 'riak'

    # We don't want Riak warnings in tests
    Riak.disable_list_keys_warnings = true
  end

  moneta_build do
    Moneta::Adapters::Riak.new(:bucket => 'adapter_riak')
  end

  moneta_specs ADAPTER_SPECS.without_increment.without_create
end
