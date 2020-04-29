shared_examples :default_expires do
  it 'sets the default expiration time', default_expires: true do
    store['key1'] = 'val1'
    advance(t_res / 4.0) # sleep less than a single time-space
    store.key?('key1').should be true
    store.fetch('key1').should == 'val1'
    store.load('key1').should == 'val1'
    advance min_ttl
    2.times { advance_next_tick }
    store.key?('key1').should be false
    store.fetch('key1').should be_nil
    store.load('key1').should be_nil
  end
end
