describe 'adapter_hbase' do
  moneta_build do
    Moneta::Adapters::HBase.new(table: 'adapter_hbase')
  end

  moneta_specs ADAPTER_SPECS.without_create
end
