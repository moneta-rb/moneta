describe 'standard_riak' do
  before :all do
    require 'riak'

    Riak.disable_list_keys_warnings = true
  end

  moneta_store :Riak, {bucket: 'standard_riak'}
  use_moneta_specs STANDARD_SPECS.without_increment.without_create
end
