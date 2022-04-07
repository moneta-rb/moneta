shared_examples :returndifferent do
  it 'guarantees that a different value is retrieved' do
    moneta_property_of(keys: 1, values: 1).check do |m|
      next if [TrueClass,FalseClass,NilClass,Numeric].any?(&m.values[0].method(:is_a?))
      store[m.keys[0]] = m.values[0]
      store[m.keys[0]].should_not be_equal(m.values[0])
    end
  end
end
