describe 'standard_riak_with_expires', unstable: true, adapter: :Riak do
  before :all do
    require 'riak'

    Riak.disable_list_keys_warnings = true
  end

  let(:t_res) { 0.125 }
  let(:min_ttl) { t_res }
  use_timecop

  moneta_store :Riak, {bucket: 'standard_riak_with_expires', expires: true}
  moneta_specs STANDARD_SPECS.without_increment.with_expires.without_create
end
