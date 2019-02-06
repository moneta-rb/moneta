shared_examples :returnsame do
  it 'guarantees that the same value is retrieved' do
    moneta_property_of(keys: 1, values: 1).check do |keys:, values:|
      next if [TrueClass,FalseClass,Numeric].any?(&values[0].method(:is_a?))
      store[keys[0]] = values[0]
      store[keys[0]].should be_equal(values[0])
    end
  end
end
