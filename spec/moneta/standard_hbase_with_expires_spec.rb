describe 'standard_hbase_with_expires' do
  moneta_store :HBase, {table: "simple_hbase", expires: true}
  moneta_specs STANDARD_SPECS.with_expires
end
