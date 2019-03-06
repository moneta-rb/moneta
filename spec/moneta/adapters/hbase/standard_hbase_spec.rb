describe 'standard_hbase', unstable: true, adapter: :HBase do
  moneta_store :HBase, {table: "simple_hbase"}
  moneta_specs STANDARD_SPECS.without_create
end
