shared_examples :returndifferent do
  it 'guarantees that a different value is retrieved' do
    moneta_property_of(keys,values).check do |key1,val1|
      next if [TrueClass,FalseClass,NilClass,Numeric].any?(&val1.method(:is_a?))
      store[key1] = val1
      store[key1].should_not be_equal(val1)
    end
  end
end
