shared_examples :not_each_key do
  it 'does not support #each_key' do
    expect do
      store.each_key
    end.to raise_error(NotImplementedError)
  end
end
