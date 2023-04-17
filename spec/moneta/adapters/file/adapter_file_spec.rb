describe 'adapter_file', adapter: :File do
  moneta_build do
    Moneta::Adapters::File.new(dir: File.join(tempdir, "adapter_file"))
  end

  moneta_specs ADAPTER_SPECS.with_each_key

  it 'refuses to write to "."' do
    store['x'] = '1'
    expect { store['.'] = '1' }.to raise_error("not a descendent")
    expect(store['x']).to eq '1'
  end

  it 'refuses to write to ".."' do
    store['x'] = '1'
    expect { store['..'] = '1' }.to raise_error("not a descendent")
    expect(store['x']).to eq '1'
  end

  it 'refuses to write to the parent' do
    store['x'] = '1'
    expect { store['../test'] = '1' }.to raise_error("not a descendent")
    expect(store['x']).to eq '1'
  end

  it 'refuses to write to a directory' do
    store['x/y'] = '1'
    expect { store['x'] = 1 }.to raise_error
    expect(store['x/y']).to eq '1'
  end

  it 'can write to the former location of a directory' do
    store['x/y'] = '1'
    store.delete('x/y')
    expect { store['x'] = 1 }.not_to raise_error
  end
end
