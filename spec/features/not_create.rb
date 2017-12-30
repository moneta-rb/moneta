shared_examples :not_create do
  it 'does not support #create' do
    expect do
      store.create('key','value')
    end.to raise_error(NotImplementedError)
  end
end
