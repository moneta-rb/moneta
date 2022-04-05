shared_examples :returnsame do
  it 'guarantees that the same value is retrieved' do
    moneta_property_of(keys: 1, values: 1).check do |m|
      next if [TrueClass, FalseClass, Numeric].any?(&m.values[0].method(:is_a?))
      store[m.keys[0]] = m.values[0]
      store[m.keys[0]].should be_equal(m.values[0])
    end
  end
end
