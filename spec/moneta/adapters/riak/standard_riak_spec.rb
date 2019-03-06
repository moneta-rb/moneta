describe 'standard_riak', isolate: true, unstable: true, adapter: :Riak do
  before :all do
    require 'riak'

    Riak.disable_list_keys_warnings = true
  end

  moneta_store :Riak, {bucket: 'standard_riak'}
  moneta_specs STANDARD_SPECS.without_increment.without_create
end
