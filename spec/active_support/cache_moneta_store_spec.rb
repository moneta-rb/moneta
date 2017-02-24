require 'moneta'
require 'active_support'
require 'active_support/cache/moneta_store'
require 'ostruct'

module MonetaStoreHelpers
  def with_notifications
    described_class.instrument = true
    yield
  ensure
    described_class.instrument = false
  end
end

RSpec.configure do |config|
  config.include(MonetaStoreHelpers)
end

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
    before(:each) do
      @rabbit = OpenStruct.new name: 'bunny'
      @white_rabbit = OpenStruct.new color: 'white'

      store.clear
      store.write 'rabbit', @rabbit
    end

    it 'reads the data' do
      store.read('rabbit').should == @rabbit
    end

    it 'writes the data' do
      store.write 'rabbit', @white_rabbit
      store.read('rabbit').should == @white_rabbit
    end

    it 'deletes data' do
      store.delete 'rabbit'
      store.read('rabbit').should be_nil
    end

    it 'verifies existence of an object in the store' do
      store.exist?('rabbit').should be true
      (!!store.exist?('rab-a-dub')).should be false
    end

    it 'fetches data' do
      store.fetch('rabbit').should == @rabbit
      store.fetch('rub-a-dub').should be_nil
      store.fetch('rub-a-dub') { 'Flora de Cana' }
      store.fetch('rub-a-dub').should == 'Flora de Cana'
    end

    it 'reads multiple keys' do
      store.write 'irish whisky', 'Jameson'
      result = store.read_multi 'rabbit', 'irish whisky'
      result['rabbit'].should == @rabbit
      result['irish whisky'].should == 'Jameson'
    end

    it 'reads multiple keys and returns only the matched ones' do
      store.delete 'irish whisky'
      result = store.read_multi 'rabbit', 'irish whisky'
      result.should_not include('irish whisky')
      result.should include('rabbit')
    end
  end

  shared_examples :expiry do
    it 'writes the data with expiration time' do
      store.write 'rabbit', @white_rabbit, expires_in: 1.second
      store.read('rabbit').should == @white_rabbit
      sleep 2
      store.read('rabbit').should be_nil
    end

    it "sets expiry on cache miss" do
      store.fetch('rabbit', force: true) # force cache miss
      store.fetch('rabbit', force: true, expires_in: 1.second) { @white_rabbit }
      store.fetch('rabbit').should == @white_rabbit
      sleep 2
      store.fetch('rabbit').should be_nil
    end

    it 'does not set expiry on cache hit' do
      store.fetch('rabbit', expires_in: 1.second) { @white_rabbit }.should == @rabbit
      sleep 2
      store.fetch('rabbit').should == @rabbit
    end
  end

  # A store *may* implement this
  shared_examples :increment_decrement do
    it 'increments a key' do
      store.write 'counter', 0, raw: true
      3.times { store.increment 'counter' }
      store.read('counter', raw: true).to_i.should == 3
    end

    it 'decrements a key' do
      store.write 'counter', 0, raw: true
      3.times { store.increment 'counter' }
      2.times { store.decrement 'counter' }
      store.read('counter', raw: true).to_i.should == 1
    end

    it 'increments a key by given value' do
      store.write 'counter', 0, raw: true
      store.increment 'counter', 3
      store.read('counter', raw: true).to_i.should == 3
    end

    it 'decrements a key by given value' do
      store.write 'counter', 0, raw: true
      3.times { store.increment 'counter' }
      store.decrement 'counter', 2
      store.read('counter', raw: true).to_i.should == 1
    end
  end

  shared_examples :basic_instrumentation do
    it 'notifies on #fetch' do
      with_notifications do
        store.fetch('radiohead') { 'House Of Cards' }
      end

      read = @events.shift
      read.name.should == 'cache_read.active_support'
      read.payload.should == { key: 'radiohead', super_operation: :fetch }

      generate = @events.shift
      generate.name.should == 'cache_generate.active_support'
      generate.payload.should == { key: 'radiohead' }

      write = @events.shift
      write.name.should == 'cache_write.active_support'
      write.payload.should == { key: 'radiohead' }
    end

    it 'notifies on #read' do
      with_notifications do
        store.read 'metallica'
      end

      read = @events.shift
      read.name.should == 'cache_read.active_support'
      read.payload.should == { key: 'metallica', hit: false }
    end

    it 'notifies on #write' do
      with_notifications do
        store.write 'depeche mode', 'Enjoy The Silence'
      end

      write = @events.shift
      write.name.should == 'cache_write.active_support'
      write.payload.should == { key: 'depeche mode' }
    end

    it 'notifies on #delete' do
      with_notifications do
        store.delete 'the new cardigans'
      end

      delete = @events.shift
      delete.name.should == 'cache_delete.active_support'
      delete.payload.should == { key: 'the new cardigans' }
    end

    it 'notifies on #exist?' do
      with_notifications do
        store.exist? 'the smiths'
      end

      exist = @events.shift
      exist.name.should == 'cache_exist?.active_support'
      exist.payload.should == { key: 'the smiths' }
    end

  end

  # This doesn't seem to be documented at all, so we follow the
  # behavior of MemCacheStore.
  shared_examples :increment_decrement_instrumentation do
    it 'notifies on #increment' do
      with_notifications do
        store.increment 'pearl jam'
      end

      increment = @events.shift
      increment.name.should == 'cache_increment.active_support'
      increment.payload.should == { key: 'pearl jam', amount: 1 }
    end

    it 'notifies on #decrement' do
      with_notifications do
        store.decrement 'placebo'
      end

      decrement = @events.shift
      decrement.name.should == 'cache_decrement.active_support'
      decrement.payload.should == { key: 'placebo', amount: 1 }
    end
  end

  describe ActiveSupport::Cache::MonetaStore do
    let(:store){ described_class.new(store: Moneta.new(:Memory)) }

    include_examples :basic_store
    include_examples :expiry
    include_examples :increment_decrement
    include_examples :basic_instrumentation
    include_examples :increment_decrement_instrumentation

    # FIXME: no other store does this -- perhaps this should be
    # removed.
    it 'notifies on #clear' do
      with_notifications do
        store.clear
      end

      clear = @events.shift
      clear.name.should == 'cache_clear.active_support'
      clear.payload.should == { key: nil }
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
    let(:store){ described_class.new }

    include_examples :basic_store
    include_examples :expiry
    include_examples :increment_decrement
    include_examples :basic_instrumentation
    include_examples :increment_decrement_instrumentation
  end
end
