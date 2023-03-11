shared_examples :default_expires do
  describe '#[]=' do
    it 'sets the default expiration time' do
      store['key1'] = 'val1'
      expect(store['key1']).to eq 'val1'
      advance min_ttl
      2.times { advance_next_tick }
      expect(store.key?('key1')).to be false
    end
  end

  describe '#key?' do
    it 'does not set an expiry by default' do
      store.store('key1', 'val1', { expires: false })
      expect(store.key?('key1')).to be true
      advance min_ttl
      2.times { advance_next_tick }
      expect(store['key1']).to eq 'val1'
    end
  end

  shared_examples :load do |method|
    it 'does not set an expiry by default' do
      store.store('key1', 'val1', { expires: false })
      expect(store.public_send(method, 'key1')).to eq 'val1'
      advance min_ttl
      2.times { advance_next_tick }
      expect(store.public_send(method, 'key1')).to eq 'val1'
    end
  end

  describe '#[]' do
    include_examples :load, :[]
  end

  describe '#load' do
    include_examples :load, :load
  end

  describe '#fetch' do
    include_examples :load, :fetch
  end

  # Disabled for now, as not all adapters support #create
  skip '#create' do
    it 'sets the default expiration time' do
      store.create('key1', 'val1')
      expect(store['key1']).to eq 'val1'
      advance min_ttl
      2.times { advance_next_tick }
      expect(store.key?('key1')).to be false
    end

    it 'does not set default expiration if `expires: false` is passed' do
      store.create('key1', 'val1', { expires: false })
      advance min_ttl
      2.times { advance_next_tick }
      expect(store['key1']).to eq 'val1'
    end

    it 'does not set default expiration if the value already exists' do
      store.create('key1', 'val1', { expires: false })
      expect(store.create('key1', 'val1')).to be false
      advance min_ttl
      2.times { advance_next_tick }
      expect(store['key1']).to eq 'val1'
    end
  end

  describe '#store' do
    it 'sets the default expiration time' do
      store.store('key1', 'val1')
      expect(store['key1']).to eq 'val1'
      advance min_ttl
      2.times { advance_next_tick }
      expect(store.key?('key1')).to be false
    end

    it 'does not set default expiration if `expires: false` is passed' do
      store.store('key1', 'val1', { expires: false })
      advance min_ttl
      2.times { advance_next_tick }
      expect(store['key1']).to eq 'val1'
    end
  end

  # Currently this isn't implemented - should it be?
  skip '#increment' do
    it 'sets the default expiration time' do
      store.increment('key1')
      expect(store['key1']).to eq '1'
      advance min_ttl
      2.times { advance_next_tick }
      expect(store.key?('key1')).to be false
    end

    it 'does not set default expiration if `expires: false` is passed' do
      store.increment('key1', 1, { expires: false })
      advance min_ttl
      2.times { advance_next_tick }
      expect(store['key1']).to eq '1'
    end
  end

  skip '#decrement' do
    it 'sets the default expiration time' do
      store.decrement('key1')
      expect(store['key1']).to eq '-1'
      advance min_ttl
      2.times { advance_next_tick }
      expect(store.key?('key1')).to be false
    end

    it 'does not set default expiration if `expires: false` is passed' do
      store.decrement('key1', 1, { expires: false })
      advance min_ttl
      2.times { advance_next_tick }
      expect(store['key1']).to eq '-1'
    end
  end

  shared_examples :merge_update do |method|
    it 'sets the default expiration time' do
      store.public_send(method, { 'key1' => 'val1' })
      expect(store['key1']).to eq 'val1'
      advance min_ttl
      2.times { advance_next_tick }
      expect(store.key?('key1')).to be false
    end

    it 'does not set default expiration if `expires: false` is passed' do
      store.public_send(method, { 'key1' => 'val1' }, { expires: false })
      advance min_ttl
      2.times { advance_next_tick }
      expect(store['key1']).to eq 'val1'
    end
  end

  describe '#merge!' do
    include_examples :merge_update, :merge!
  end

  describe '#update' do
    include_examples :merge_update, :update
  end

  describe '#values_at' do
    it 'does not set an expiry by default' do
      store.store('key1', 'val1', { expires: false })
      expect(store.values_at('key1')).to eq ['val1']
      advance min_ttl
      2.times { advance_next_tick }
      expect(store['key1']).to eq 'val1'
    end
  end

  describe '#fetch_values' do
    it 'does not set an expiry by default' do
      store.store('key1', 'val1', { expires: false })
      expect(store.fetch_values('key1')).to eq ['val1']
      advance min_ttl
      2.times { advance_next_tick }
      expect(store['key1']).to eq 'val1'
    end
  end

  describe '#slice' do
    it 'does not set an expiry by default' do
      store.store('key1', 'val1', { expires: false })
      expect(store.slice('key1').to_a).to eq [%w{key1 val1}]
      advance min_ttl
      2.times { advance_next_tick }
      expect(store['key1']).to eq 'val1'
    end
  end
end
