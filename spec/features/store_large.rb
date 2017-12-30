shared_examples :store_large do
  it 'should store values up to 32k' do
    value = 'x' * (32 * 1024)
    store['large'] = value
    store['large'].should == value
  end

  it 'should store keys up to 128 bytes' do
    key = 'x' * 128
    store[key] = 'value'
    store[key].should == 'value'
  end
end
