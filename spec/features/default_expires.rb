shared_examples :default_expires do
  it 'does set default expiration time' do
    store['key1'] = 'val1'
    store.key?('key1').should be true
    store.fetch('key1').should == 'val1'
    store.load('key1').should == 'val1'
    sleep 2
    store.key?('key1').should be false
    store.fetch('key1').should be_nil
    store.load('key1').should be_nil
  end
end
