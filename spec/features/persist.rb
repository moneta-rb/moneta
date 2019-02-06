shared_examples :persist do
  it 'persists values' do
    moneta_property_of(keys: 1, values: 1).check do |keys:, values:|
      new_store.tap do |store|
        store[keys[0]] = values[0]
        store.close
      end
      new_store.tap do |store|
        store[keys[0]].should == values[0]
        store.close
      end
    end
  end
end
