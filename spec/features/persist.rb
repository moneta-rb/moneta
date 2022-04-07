shared_examples :persist do
  it 'persists values' do
    moneta_property_of(keys: 1, values: 1).check do |m|
      new_store.tap do |store|
        store[m.keys[0]] = m.values[0]
        store.close
      end
      new_store.tap do |store|
        store[m.keys[0]].should == m.values[0]
        store.close
      end
    end
  end
end
