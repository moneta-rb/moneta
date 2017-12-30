shared_examples :transform_value do
  it 'allows to bypass transformer with :raw' do
    store['key'] = 'value'
    load_value(store.load('key', raw: true)).should == 'value'

    store.store('key', 'value', raw: true)
    store.load('key', raw: true).should == 'value'
    store.delete('key', raw: true).should == 'value'
  end

  it 'allows to bypass transformer with raw syntactic sugar' do
    store['key'] = 'value'
    load_value(store.raw.load('key')).should == 'value'

    store.raw.store('key', 'value')
    store.raw['key'].should == 'value'
    store.raw.load('key').should == 'value'
    store.raw.delete('key').should == 'value'

    store.raw['key'] = 'value2'
    store.raw['key'].should == 'value2'
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
