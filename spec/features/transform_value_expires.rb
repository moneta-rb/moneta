shared_examples :transform_value_expires do
  it 'allows to bypass transformer with :raw' do
    store['key'] = 'value'
    load_value(store.load('key', raw: true)).should == 'value'
    store['key'] = [1,2,3]
    load_value(store.load('key', raw: true)).should == [[1,2,3]]
    store['key'] = nil
    load_value(store.load('key', raw: true)).should == [nil]
    store['key'] = false
    load_value(store.load('key', raw: true)).should be false

    store.store('key', 'value', expires: 10)
    load_value(store.load('key', raw: true)).first.should == 'value'
    load_value(store.load('key', raw: true)).last.should respond_to(:to_int)

    store.store('key', 'value', raw: true)
    store.load('key', raw: true).should == 'value'
    store.delete('key', raw: true).should == 'value'
  end

  it 'returns unmarshalled value' do
    store.store('key', 'unmarshalled value', raw: true)
    store.load('key', raw: true).should == 'unmarshalled value'
  end

  it 'might raise exception on invalid value' do
    store.store('key', 'unmarshalled value', raw: true)

    begin
      store['key'].should == load_value('unmarshalled value')
      store.delete('key').should == load_value('unmarshalled value')
    rescue Exception => ex
      expect do
        store['key']
      end.to raise_error
      expect do
        store.delete('key')
      end.to raise_error
    end
  end
end
