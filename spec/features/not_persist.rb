shared_examples :not_persist do
  it 'does not persist values' do
    store['key'] = 'val'
    store.close
    @store = nil

    store['key'].should be_nil
  end
end
