shared_examples :increment do
  it 'initializes in #increment with 1' do
    expect(store.key?('inckey')).to be false
    expect(store.increment('inckey')).to eq 1
    expect(store.key?('inckey')).to be true
    expect(store.raw['inckey'].to_s).to match(/^1\b/)
    expect(store.raw.load('inckey').to_s).to match(/^1\b/)
    expect(store.load('inckey', raw: true).to_s).to match(/^1\b/)

    expect(store.delete('inckey', raw: true).to_s).to match(/^1\b/)
    expect(store.key?('inckey')).to be false
  end

  it 'initializes in #increment with higher value' do
    expect(store.increment('inckey', 42)).to eq 42
    expect(store.key?('inckey')).to be true
    expect(store.raw['inckey'].to_s).to match(/^42\b/)
    expect(store.delete('inckey', raw: true).to_s).to match(/^42\b/)
  end

  it 'initializes in #increment with 0' do
    expect(store.increment('inckey', 0)).to eq 0
    expect(store.key?('inckey')).to be true
    expect(store.raw['inckey'].to_s).to match(/^0\b/)
    expect(store.delete('inckey', raw: true).to_s).to match(/^0\b/)
  end

  it 'initializes in #decrement with 0' do
    expect(store.decrement('inckey', 0)).to eq 0
    expect(store.raw['inckey'].to_s).to match(/^0\b/)
  end

  it 'initializes in #decrement with negative value' do
    expect(store.decrement('inckey', -42)).to eq 42
    expect(store.raw['inckey'].to_s).to match(/^42\b/)
  end

  it 'supports incrementing existing value by value' do
    expect(store.increment('inckey')).to eq 1
    expect(store.increment('inckey', 42)).to eq 43
    expect(store.raw['inckey'].to_s).to match(/^43\b/)
  end

  it 'supports decrementing existing value by value' do
    expect(store.increment('inckey')).to eq 1
    expect(store.decrement('inckey')).to eq 0
    expect(store.increment('inckey', 42)).to eq 42
    expect(store.decrement('inckey', 2)).to eq 40
    expect(store.raw['inckey'].to_s).to match(/^40\b/)
  end

  it 'supports incrementing existing value by 0' do
    expect(store.increment('inckey')).to eq 1
    expect(store.increment('inckey', 0)).to eq 1
    expect(store.raw['inckey'].to_s).to match(/^1\b/)
  end

  it 'supports decrementing existing value' do
    expect(store.increment('inckey', 10)).to eq 10
    expect(store.increment('inckey', -5)).to eq 5
    expect(store.raw['inckey'].to_s).to match(/^5\b/)
    expect(store.increment('inckey', -5)).to eq 0
    expect(store.raw['inckey'].to_s).to match(/^0\b/)
  end

  it 'interprets raw value as integer' do
    store.store('inckey', '42', raw: true)
    expect(store.increment('inckey')).to eq 43
    expect(store.raw['inckey'].to_s).to match(/^43\b/)
  end

  it 'raises error in #increment on non integer value' do
    store['strkey'] = 'value'
    expect do
      store.increment('strkey')
    end.to raise_error
  end

  it 'raises error in #decrement on non integer value' do
    store['strkey'] = 'value'
    expect do
      store.decrement('strkey')
    end.to raise_error
  end

  it 'supports Semaphore' do
    a = Moneta::Semaphore.new(store, 'semaphore', 2)
    b = Moneta::Semaphore.new(store, 'semaphore', 2)
    c = Moneta::Semaphore.new(store, 'semaphore', 2)
    a.synchronize do
      expect(a.locked?).to be true
      b.synchronize do
        expect(b.locked?).to be true
        expect(c.try_lock).to be false
      end
    end
  end
end
