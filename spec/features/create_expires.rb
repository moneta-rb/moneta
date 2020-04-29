shared_examples :create_expires do
  it 'creates the given key and expires it' do
    store.create('key','value', expires: min_ttl).should be true
    store['key'].should == 'value'
    advance min_ttl
    2.times { advance_next_tick }
    store.key?('key').should be false
  end

  it 'does not change expires if the key exists' do
    store.store('key', 'value', expires: false).should == 'value'
    store.create('key','another value', expires: min_ttl).should be false
    store['key'].should == 'value'
    advance min_ttl
    2.times { advance_next_tick }
    store['key'].should == 'value'
    store.key?('key').should be true
  end
end
