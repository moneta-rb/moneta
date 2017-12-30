shared_examples :marshallable_value do
  it 'refuses to store values that cannot be marshalled' do
    expect do
      store.store 'key', Struct.new(:foo).new(:bar)
    end.to raise_error(marshal_error)
  end
end
