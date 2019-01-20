describe 'standard_hbase_with_expires', isolate: true, unstable: true do
  let(:t_res){ 0.1 }
  let(:min_ttl){ t_res }

  moneta_store :HBase, {table: "simple_hbase", expires: true}
  moneta_specs STANDARD_SPECS.with_expires
end
