describe 'standard_hbase_with_expires', unstable: true do
  let(:t_res) { 0.125 }
  let(:min_ttl) { t_res }
  use_timecop

  moneta_store :HBase, {table: "simple_hbase", expires: true}
  moneta_specs STANDARD_SPECS.with_expires
end
