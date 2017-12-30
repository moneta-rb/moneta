shared_examples :multiprocess do
  it 'supports access by multiple instances/processes' do
    store['key'] = 'val'
    store2 = new_store
    store2['key'].should == 'val'
    store2.close
  end
end
