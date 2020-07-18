describe 'metadata_memory', proxy: :Metadata do
  moneta_build do
    Moneta.build do
      use :Metadata, names: %i{test1 test2}
      adapter :Memory
    end
  end

  moneta_specs STANDARD_SPECS.without_transform.without_persist.returnsame.with_each_key

  it 'raises an exception when loading an invalid value' do
    store.store('key', 'unmarshalled value', raw: true)

    expect { store['key'] }.to raise_error
    expect { store.delete('key') }.to raise_error
  end
end

