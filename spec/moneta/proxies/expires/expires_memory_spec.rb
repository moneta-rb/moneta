describe 'expires_memory', proxy: :Expires do
  let(:t_res) { 0.125 }
  let(:min_ttl) { t_res }

  use_timecop

  moneta_build do
    Moneta.build do
      use :Expires
      adapter :Memory
    end
  end

  moneta_specs STANDARD_SPECS.without_transform.with_expires.without_persist.returnsame.with_each_key

  it 'raises an exception when loading an invalid value' do
    store.store('key', 'unmarshalled value', raw: true)

    expect { store['key'] }.to raise_error
    expect { store.delete('key') }.to raise_error
  end
end
