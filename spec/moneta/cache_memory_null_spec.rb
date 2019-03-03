describe 'cache_memory_null' do
  moneta_build do
    Moneta.build do
      use(:Cache) do
        adapter(Moneta::Adapters::Memory.new)
        cache(Moneta::Adapters::Null.new)
      end
    end
  end

  moneta_specs ADAPTER_SPECS.without_persist.returnsame.with_each_key
end
