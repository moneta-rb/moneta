shared_examples :create do
  it 'creates the given key' do
    store.create('key','value').should be true
    store['key'].should == 'value'
  end

  it 'creates raw value with the given key' do
    store.raw.create('key','value').should be true
    store.raw['key'].should == 'value'
  end

  it 'does not create a key if it exists' do
    store['key'] = 'value'
    store.create('key','another value').should be false
    store['key'].should == 'value'
  end

  it 'supports Mutex' do
    a = Moneta::Mutex.new(store, 'mutex')
    b = Moneta::Mutex.new(store, 'mutex')
    a.lock.should be true
    b.try_lock.should be false
    a.unlock.should be_nil
  end
end
