shared_examples :persist do
  it 'persists values' do
    moneta_property_of(keys,values).check do |key1,val1|
      new_store.tap do |store|
        store[key1] = val1
        store.close
      end
      new_store.tap do |store|
        store[key1].should == val1
        store.close
      end
    end
  end
end
