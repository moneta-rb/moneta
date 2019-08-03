describe 'enumerable', proxy: :Enumerable do
  moneta_build do
    Moneta.build do
      use :Enumerable
      adapter :Memory
    end
  end

  moneta_specs STANDARD_SPECS.without_transform.returnsame.without_persist.with_each_key

  it 'includes the enumerable interface' do
    expect(store).to be_a Enumerable
    expect(Enumerable.instance_methods).to all satisfy { |m| store.respond_to? m }
  end

  it 'allows enumeration over key-value pairs' do
    moneta_property_of(keys: 100, values: 100) do |keys:, values:|
      pairs = keys.zip(values)
      store.merge!(pairs)
      expect(store.to_a).to contain_exactly(*pairs)
      expect(store.each.to_a).to contain_exactly(*pairs)
      expect(store.each_pair.to_a).to contain_exactly(*pairs)
      store.clear
    end
  end
end
