describe 'metadata_memory', proxy: :Metadata do
  moneta_build do |metadata: %i{test1 test2}, **options|
    Moneta.build do
      use :Metadata, metadata: metadata
      adapter :Memory, options
    end
  end

  moneta_specs STANDARD_SPECS.without_transform.without_persist.returnsame.with_each_key.with_metadata

  it 'raises an exception when loading an invalid value' do
    store.store('key', 'unmarshalled value', raw: true)

    expect { store['key'] }.to raise_error
    expect { store.delete('key') }.to raise_error
  end
end

