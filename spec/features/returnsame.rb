shared_examples :returnsame do
  it 'guarantees that the same value is retrieved' do
    moneta_property_of(keys,values).check do |key1,val1|
      next if [TrueClass,FalseClass,Numeric].any?(&val1.method(:is_a?))
      value = val1
      store[key1] = value
      store[key1].should be_equal(value)
    end
  end
end
