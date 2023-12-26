describe "optionmerger", proxy: :OptionMerger do
  moneta_store :Memory

  it '#with should return OptionMerger' do
    options = { optionname: :optionvalue }
    merger = store.with(options)
    expect(merger).to be_a Moneta::OptionMerger
  end

  it 'saves default options' do
    options = { optionname: :optionvalue }
    merger = store.with(options)
    Moneta::OptionMerger::METHODS.each do |method|
      merger.default_options[method].should equal(options)
    end
  end

  it 'has method #raw' do
    expect(store.raw.default_options).to eq(
      store: { raw: true },
      create: { raw: true },
      load: { raw: true },
      delete: { raw: true },
      fetch_values: { raw: true },
      merge!: { raw: true },
      slice: { raw: true },
      values_at: { raw: true }
    )

    expect(store.raw.raw).to be store.raw
  end

  it 'has method #expires' do
    expect(store.expires(10).default_options).to eq(
      store: { expires: 10 },
      create: { expires: 10 },
      increment: { expires: 10 },
      merge!: { expires: 10 }
    )
  end

  describe '#prefix' do
    it 'creates a store' do
      prefixed = store.prefix('test')
      expect(prefixed).to be_a Moneta::Proxy
    end

    it 'allows fetching keys by specifying the suffix' do
      store['a:x'] = 1

      prefixed = store.prefix('a:')

      expect(prefixed['x']).to eq 1
      expect(prefixed.slice('x')).to eq [['x', 1]]
      expect(prefixed.values_at('x')).to eq [1]
      expect(prefixed.fetch_values('x')).to eq [1]
    end

    it 'allows storing keys by specifying the suffix' do
      prefixed = store.prefix('a:')

      prefixed['x'] = 1
      expect(store['a:x']).to eq 1

      prefixed.increment('w', 1)
      expect(store.load('a:w', raw: true)).to eq '1'

      prefixed.merge!('y' => 2)
      expect(store['a:y']).to eq 2

      expect(prefixed.delete('y')).to eq 2
    end

    it 'can be chained to build up a prefix' do
      prefixed = store.prefix('a:').prefix('b:')
      prefixed['x'] = 1

      expect(store['a:b:x']).to be 1
    end
  end

  it 'supports adding proxies using #with' do
    compressed_store = store.with(prefix: 'compressed') do
      use :Transformer, value: :zlib
    end
    store['key'] = 'uncompressed value'
    compressed_store['key'] = 'compressed value'
    store['key'].should == 'uncompressed value'
    compressed_store['key'].should == 'compressed value'
    store.key?('compressedkey').should be true
    # Check if value is compressed
    compressed_store['key'].should_not == store['compressedkey']
  end
end
