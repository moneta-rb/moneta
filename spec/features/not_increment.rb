shared_examples :not_increment do
  it 'does not support #increment' do
    expect do
      store.increment('inckey')
    end.to raise_error(NotImplementedError)
  end

  it 'does not support #decrement' do
    expect do
      store.increment('inckey')
    end.to raise_error(NotImplementedError)
  end
end
