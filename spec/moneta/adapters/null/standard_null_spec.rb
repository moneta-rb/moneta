describe 'standard_null', adapter: :Null do
  moneta_store :Null
  moneta_specs STANDARD_SPECS.without_increment.without_create.without_store.without_persist

  it 'works when constructed with a proxy object' do
    store = Moneta.new(:Null, expires: 1)
    expect { store['moneta'] = 'test' }.not_to raise_error
  end
end
