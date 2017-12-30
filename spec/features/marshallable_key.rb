shared_examples :marshallable_key do
  it 'refuses to #[] from keys that cannot be marshalled' do
    expect do
      store[Struct.new(:foo).new(:bar)]
    end.to raise_error(marshal_error)
  end

  it 'refuses to load from keys that cannot be marshalled' do
    expect do
      store.load(Struct.new(:foo).new(:bar))
    end.to raise_error(marshal_error)
  end

  it 'refuses to fetch from keys that cannot be marshalled' do
    expect do
      store.fetch(Struct.new(:foo).new(:bar), true)
    end.to raise_error(marshal_error)
  end

  it 'refuses to #[]= to keys that cannot be marshalled' do
    expect do
      store[Struct.new(:foo).new(:bar)] = 'value'
    end.to raise_error(marshal_error)
  end

  it 'refuses to store to keys that cannot be marshalled' do
    expect do
      store.store Struct.new(:foo).new(:bar), 'value'
    end.to raise_error(marshal_error)
  end

  it 'refuses to check for #key? if the key cannot be marshalled' do
    expect do
      store.key? Struct.new(:foo).new(:bar)
    end.to raise_error(marshal_error)
  end

  it 'refuses to delete a key if the key cannot be marshalled' do
    expect do
      store.delete Struct.new(:foo).new(:bar)
    end.to raise_error(marshal_error)
  end
end
