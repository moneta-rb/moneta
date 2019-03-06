describe 'adapter_couch', isolate: true, adapter: :Couch do
  moneta_build do
    Moneta::Adapters::Couch.new(db: 'adapter_couch')
  end

  moneta_specs ADAPTER_SPECS.without_increment.simplevalues_only.without_path.with_each_key
end
