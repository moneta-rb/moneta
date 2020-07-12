shared_examples :transform_value_expires do
  it 'allows to bypass transformer with :raw' do
    store['key'] = 'value'
    expect(load_value(store.load('key', raw: true))).to eq ['value', nil]
    store['key'] = [1,2,3]
    expect(load_value(store.load('key', raw: true))).to eq [[1,2,3], nil]
    store['key'] = nil
    expect(load_value(store.load('key', raw: true))).to eq [nil, nil]
    store['key'] = false
    expect(load_value(store.load('key', raw: true))).to eq [false, nil]

    store.store('key', 'value', expires: 10)
    expect(load_value(store.load('key', raw: true)).first).to eq 'value'
    expect(load_value(store.load('key', raw: true)).last).to respond_to(:to_int)

    store.store('key', 'value', raw: true)
    expect(store.load('key', raw: true)).to eq 'value'
    expect(store.delete('key', raw: true)).to eq 'value'
  end

  it 'returns unmarshalled value' do
    store.store('key', 'unmarshalled value', raw: true)
    expect(store.load('key', raw: true)).to eq 'unmarshalled value'
  end

  it 'might raise exception on invalid value' do
    store.store('key', 'unmarshalled value', raw: true)

    begin
      expect(store['key']).to eq load_value('unmarshalled value')
      expect(store.delete('key')).to eq load_value('unmarshalled value')
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
