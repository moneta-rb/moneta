describe 'adapter_memory', adapter: :Memory do
  moneta_build do
    Moneta::Adapters::Memory.new
  end

  moneta_specs STANDARD_SPECS.with_each_key.without_transform.returnsame.without_persist
end
