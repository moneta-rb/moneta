shared_examples :returndifferent do
  it 'guarantees that a different value is retrieved' do
    moneta_property_of(keys: 1, values: 1).check do |keys:, values:|
      next if [TrueClass,FalseClass,NilClass,Numeric].any?(&values[0].method(:is_a?))
      store[keys[0]] = values[0]
      store[keys[0]].should_not be_equal(values[0])
    end
  end
end
