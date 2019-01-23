describe 'standard_hbase', broken: true do
  moneta_store :HBase, {table: "simple_hbase"}
  moneta_specs STANDARD_SPECS.without_create
end
