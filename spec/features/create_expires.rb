shared_examples :create_expires do
  it 'creates the given key and expires it' do
    store.create('key','value', expires: 1).should be true
    store['key'].should == 'value'
    sleep 2
    store.key?('key').should be false
  end

  it 'does not change expires if the key exists' do
    store.store('key', 'value', expires: false).should == 'value'
    store.create('key','another value', expires: 1).should be false
    store['key'].should == 'value'
    sleep 2
    store['key'].should == 'value'
    store.key?('key').should be true
  end
end
