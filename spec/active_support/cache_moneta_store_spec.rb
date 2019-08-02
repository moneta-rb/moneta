require 'moneta'
require 'active_support'
require 'active_support/cache/moneta_store'
require 'ostruct'
require_relative '../moneta/adapters/memcached_helper.rb'

describe "cache_moneta_store" do
  before(:all) do
    @events = []
    ActiveSupport::Notifications.subscribe(/^cache_(.*)\.active_support$/) do |*args|
      @events << ActiveSupport::Notifications::Event.new(*args)
    end
  end

  before(:each) do
    @events.clear
  end

  # All stores should implement this basic behavior.
  shared_examples :basic_store do
    let(:rabbit) { OpenStruct.new name: 'bunny' }
    let(:white_rabbit) { OpenStruct.new color: 'white' }

    before(:each) do
      store.clear
      store.write 'rabbit', rabbit
      @events.clear
    end

    it 'reads the data' do
      expect(store.read('rabbit')).to eq rabbit
    end

    it 'writes the data' do
      store.write 'rabbit', white_rabbit
      expect(store.read('rabbit')).to eq white_rabbit
    end

    it 'deletes data' do
      store.delete 'rabbit'
      expect(store.read('rabbit')).to be_nil
    end

    it 'verifies existence of an object in the store' do
      expect(store.exist?('rabbit')).to be true
      expect(!!store.exist?('rab-a-dub')).to be false
    end

    it 'fetches data' do
      expect(store.fetch('rabbit')).to eq rabbit
      expect(store.fetch('rub-a-dub')).to be_nil
      store.fetch('rub-a-dub') { 'Flora de Cana' }
      expect(store.fetch('rub-a-dub')).to eq 'Flora de Cana'
    end

    it 'reads multiple keys' do
      store.write 'irish whisky', 'Jameson'
      result = store.read_multi 'rabbit', 'irish whisky'
      expect(result['rabbit']).to eq rabbit
      expect(result['irish whisky']).to eq 'Jameson'
    end

    it 'reads multiple keys and returns only the matched ones' do
      store.delete 'irish whisky'
      result = store.read_multi 'rabbit', 'irish whisky'
      expect(result).not_to include('irish whisky')
      expect(result).to include('rabbit')
    end

    it 'fetches multiple keys and fills in the missing ones' do
      store.delete 'irish whisky'
      result = store.fetch_multi('rabbit', 'irish whisky') do |k|
        k + ' was missing'
      end
      expect(result['rabbit']).to eq rabbit
      expect(result['irish whisky']).to eq 'irish whisky was missing'
      expect(store.fetch 'irish whisky').to eq 'irish whisky was missing'
    end
  end

  shared_examples :expiry do
    at_each_usec do
      it 'writes the data with expiration time' do
        store.write 'rabbit', white_rabbit, expires_in: 0.2.second
        expect(store.read('rabbit')).to eq white_rabbit
        sleep 0.3
        expect(store.read('rabbit')).to be_nil
      end

      it 'writes multiple values with expiration time' do
        store.write_multi({
          'rabbit' => white_rabbit,
          'irish whisky' => 'Jameson'
        }, expires_in: 0.2.second)

        expect(store.read_multi('rabbit', 'irish whisky')).to eq \
          'rabbit' => white_rabbit,
          'irish whisky' => 'Jameson'

        sleep 0.3
        expect(store.read_multi('rabbit', 'irish whisky')).to be_empty
      end

      it "sets expiry on cache miss" do
        store.fetch('rabbit', force: true, expires_in: 0.2.second) { white_rabbit }
        expect(store.fetch('rabbit')).to eq white_rabbit
        sleep 0.3
        expect(store.fetch('rabbit')).to be_nil
      end

      it 'does not set expiry on cache hit' do
        expect(store.fetch('rabbit', expires_in: 0.2.second) { white_rabbit }).to eq rabbit
        sleep 0.3
        expect(store.fetch('rabbit')).to eq rabbit
      end
    end
  end

  # A store *may* implement this
  shared_examples :increment_decrement do
    it 'increments a key' do
      store.write 'counter', 0, raw: true
      (1..3).each do |i|
        expect(store.increment('counter')).to eq i
      end
      expect(store.read('counter', raw: true).to_i).to eq 3
    end

    it 'decrements a key' do
      store.write 'counter', 0, raw: true
      3.times { store.increment 'counter' }
      2.times { store.decrement 'counter' }
      expect(store.read('counter', raw: true).to_i).to eq 1
    end

    it 'increments a key by given value' do
      store.write 'counter', 0, raw: true
      store.increment 'counter', 3
      expect(store.read('counter', raw: true).to_i).to eq 3
    end

    it 'decrements a key by given value' do
      store.write 'counter', 0, raw: true
      3.times { store.increment 'counter' }
      store.decrement 'counter', 2
      expect(store.read('counter', raw: true).to_i).to eq 1
    end
  end

  shared_examples :basic_instrumentation do
    it 'notifies on #fetch' do
      store.fetch('radiohead') { 'House Of Cards' }

      read = @events.shift
      expect(read.name).to eq 'cache_read.active_support'
      expect(read.payload).to include(key: 'radiohead', super_operation: :fetch, hit: false)

      generate = @events.shift
      expect(generate.name).to eq 'cache_generate.active_support'
      expect(generate.payload).to include(key: 'radiohead')

      write = @events.shift
      expect(write.name).to eq 'cache_write.active_support'
      expect(write.payload).to include(key: 'radiohead')
    end

    it 'notifies on #read' do
      store.read 'metallica'

      read = @events.shift
      expect(read.name).to eq 'cache_read.active_support'
      expect(read.payload).to include(key: 'metallica', hit: false)
    end

    it 'notifies on #write' do
      store.write 'depeche mode', 'Enjoy The Silence'

      write = @events.shift
      expect(write.name).to eq 'cache_write.active_support'
      expect(write.payload).to include(key: 'depeche mode')
    end

    it 'notifies on #delete' do
      store.delete 'the new cardigans'

      delete = @events.shift
      expect(delete.name).to eq 'cache_delete.active_support'
      expect(delete.payload).to include(key: 'the new cardigans')
    end

    it 'notifies on #exist?' do
      store.exist? 'the smiths'

      exist = @events.shift
      expect(exist.name).to eq 'cache_exist?.active_support'
      expect(exist.payload).to include(key: 'the smiths')
    end
  end

  # This doesn't seem to be documented at all, so we follow the
  # behavior of MemCacheStore.
  shared_examples :increment_decrement_instrumentation do
    it 'notifies on #increment' do
      store.increment 'pearl jam'

      increment = @events.shift
      expect(increment.name).to eq 'cache_increment.active_support'
      expect(increment.payload).to eq(key: 'pearl jam', amount: 1)
    end

    it 'notifies on #decrement' do
      store.decrement 'placebo'
      decrement = @events.shift
      expect(decrement.name).to eq 'cache_decrement.active_support'
      expect(decrement.payload).to eq(key: 'placebo', amount: 1)
    end
  end

  describe ActiveSupport::Cache::MonetaStore do
    shared_examples :moneta_store do
      include_examples :basic_store
      include_examples :expiry
      include_examples :increment_decrement
      include_examples :basic_instrumentation
      include_examples :increment_decrement_instrumentation

      # FIXME: no other store does this -- perhaps this should be
      # removed.
      it 'notifies on #clear' do
        store.clear

        clear = @events.shift
        expect(clear.name).to eq 'cache_clear.active_support'
        expect(clear.payload).to eq(key: nil)
      end
    end

    context "with :Memory store" do
      let(:store){ described_class.new(store: :Memory) }
      include_examples :moneta_store
    end

    context "with existing :Memory store" do
      let(:store){ described_class.new(store: ::Moneta.new(:Memory)) }
      include_examples :moneta_store
    end

    context "with Redis store" do
      let(:store) {described_class.new(store: :Redis) }
      include_examples :moneta_store
    end
  end

  describe ActiveSupport::Cache::MemoryStore do
    let(:store){ described_class.new }

    include_examples :basic_store
    include_examples :expiry
    include_examples :increment_decrement
    include_examples :basic_instrumentation
  end

  describe ActiveSupport::Cache::MemCacheStore do
    let(:store){ described_class.new('127.0.0.1:11213') }

    include_context :start_memcached, 11213

    include_examples :basic_store
    include_examples :expiry
    include_examples :increment_decrement
    include_examples :basic_instrumentation
    include_examples :increment_decrement_instrumentation
  end

  describe ActiveSupport::Cache::RedisCacheStore do
    let(:store){ described_class.new(url: 'redis:///3') }

    include_examples :basic_store
    include_examples :expiry
    include_examples :increment_decrement
    include_examples :basic_instrumentation
    include_examples :increment_decrement_instrumentation
  end
end
