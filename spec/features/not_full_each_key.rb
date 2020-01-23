shared_examples :not_full_each_key do
  it 'does not fully support #each_key' do
    expect do
      store.each_key
    end.to_not raise_error(NotImplementedError)
  end
end
