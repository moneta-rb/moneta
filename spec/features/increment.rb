shared_examples :increment do
  it 'initializes in #increment with 1' do
    store.key?('inckey').should be false
    store.increment('inckey').should == 1
    store.key?('inckey').should be true
    store.raw['inckey'].should == '1'
    store.raw.load('inckey').should == '1'
    store.load('inckey', raw: true).should == '1'

    store.delete('inckey', raw: true).should == '1'
    store.key?('inckey').should be false
  end

  it 'initializes in #increment with higher value' do
    store.increment('inckey', 42).should == 42
    store.key?('inckey').should be true
    store.raw['inckey'].should == '42'
    store.delete('inckey', raw: true).should == '42'
  end

  it 'initializes in #increment with 0' do
    store.increment('inckey', 0).should == 0
    store.key?('inckey').should be true
    store.raw['inckey'].should == '0'
    store.delete('inckey', raw: true).should == '0'
  end

  it 'initializes in #decrement with 0' do
    store.decrement('inckey', 0).should == 0
    store.raw['inckey'].should == '0'
  end

  it 'initializes in #decrement with negative value' do
    store.decrement('inckey', -42).should == 42
    store.raw['inckey'].should == '42'
  end

  it 'supports incrementing existing value by value' do
    store.increment('inckey').should == 1
    store.increment('inckey', 42).should == 43
    store.raw['inckey'].should == '43'
  end

  it 'supports decrementing existing value by value' do
    store.increment('inckey').should == 1
    store.decrement('inckey').should == 0
    store.increment('inckey', 42).should == 42
    store.decrement('inckey', 2).should == 40
    store.raw['inckey'].should == '40'
  end

  it 'supports incrementing existing value by 0' do
    store.increment('inckey').should == 1
    store.increment('inckey', 0).should == 1
    store.raw['inckey'].should == '1'
  end

  it 'supports decrementing existing value' do
    store.increment('inckey', 10).should == 10
    store.increment('inckey', -5).should == 5
    store.raw['inckey'].should == '5'
    store.increment('inckey', -5).should == 0
    store.raw['inckey'].should == '0'
  end

  it 'interprets raw value as integer' do
    store.store('inckey', '42', raw: true)
    store.increment('inckey').should == 43
    store.raw['inckey'].should == '43'
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
      a.locked?.should be true
      b.synchronize do
        b.locked?.should be true
        c.try_lock.should be false
      end
    end
  end
end
