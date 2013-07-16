require 'moneta'
require 'active_support'
require 'active_support/cache/moneta_store'
require 'ostruct'

describe ActiveSupport::Cache::MonetaStore do
  before(:all) do
    @events = []
    ActiveSupport::Notifications.subscribe(/^cache_(.*)\.active_support$/) do |*args|
      @events << ActiveSupport::Notifications::Event.new(*args)
    end
  end

  before(:each) do
    @events.clear
    @store  = ActiveSupport::Cache::MonetaStore.new(:store => Moneta.new(:Memory))
    @rabbit = OpenStruct.new :name => 'bunny'
    @white_rabbit = OpenStruct.new :color => 'white'

    @store.write 'rabbit', @rabbit
    @store.delete 'counter'
    @store.delete 'rub-a-dub'
  end

  it 'reads the data' do
    @store.read('rabbit').should == @rabbit
  end

  it 'writes the data' do
    @store.write 'rabbit', @white_rabbit
    @store.read('rabbit').should == @white_rabbit
  end

  it 'writes the data with expiration time' do
    @store.write 'rabbit', @white_rabbit, :expires_in => 1.second
    @store.read('rabbit').should == @white_rabbit
    sleep 2
    @store.read('rabbit').should be_nil
  end

  it 'deletes data' do
    @store.delete 'rabbit'
    @store.read('rabbit').should be_nil
  end

  it 'verifies existence of an object in the store' do
    @store.exist?('rabbit').should == true
    (!!@store.exist?('rab-a-dub')).should == false
  end

  it 'fetches data' do
    @store.fetch('rabbit').should == @rabbit
    @store.fetch('rub-a-dub').should be_nil
    @store.fetch('rub-a-dub') { 'Flora de Cana' }
    @store.fetch('rub-a-dub').should == 'Flora de Cana'
    @store.fetch('rabbit', :force => true) # force cache miss
    @store.fetch('rabbit', :force => true, :expires_in => 1.second) { @white_rabbit }
    @store.fetch('rabbit').should == @white_rabbit
    sleep 2
    @store.fetch('rabbit').should be_nil
  end

  it 'reads multiple keys' do
    @store.write 'irish whisky', 'Jameson'
    result = @store.read_multi 'rabbit', 'irish whisky'
    result['rabbit'].should == @rabbit
    result['irish whisky'].should == 'Jameson'
  end

  it 'reads multiple keys and returns only the matched ones' do
    @store.delete 'irish whisky'
    result = @store.read_multi 'rabbit', 'irish whisky'
    result.should_not include('irish whisky')
    result.should include('rabbit')
  end

  it 'increments a key' do
    3.times { @store.increment 'counter' }
    @store.read('counter', :raw => true).should == '3'
  end

  it 'decrements a key' do
    3.times { @store.increment 'counter' }
    2.times { @store.decrement 'counter' }
    @store.read('counter', :raw => true).should == '1'
  end

  it 'increments a key by given value' do
    @store.increment 'counter', 3
    @store.read('counter', :raw => true).should == '3'
  end

  it 'decrements a key by given value' do
    3.times { @store.increment 'counter' }
    @store.decrement 'counter', 2
    @store.read('counter', :raw => true).should == '1'
  end

  describe 'notifications' do
    it 'notifies on #fetch' do
      with_notifications do
        @store.fetch('radiohead') { 'House Of Cards' }
      end

      read, generate, write = @events

      read.name.should == 'cache_read.active_support'
      read.payload.should == { :key => 'radiohead', :super_operation => :fetch }

      generate.name.should == 'cache_generate.active_support'
      generate.payload.should == { :key => 'radiohead' }

      write.name.should == 'cache_write.active_support'
      write.payload.should == { :key => 'radiohead' }
    end

    it 'notifies on #read' do
      with_notifications do
        @store.read 'metallica'
      end

      read = @events.first
      read.name.should == 'cache_read.active_support'
      read.payload.should == { :key => 'metallica', :hit => false }
    end

    it 'notifies on #write' do
      with_notifications do
        @store.write 'depeche mode', 'Enjoy The Silence'
      end

      write = @events.first
      write.name.should == 'cache_write.active_support'
      write.payload.should == { :key => 'depeche mode' }
    end

    it 'notifies on #delete' do
      with_notifications do
        @store.delete 'the new cardigans'
      end

      delete = @events.first
      delete.name.should == 'cache_delete.active_support'
      delete.payload.should == { :key => 'the new cardigans' }
    end

    it 'notifies on #exist?' do
      with_notifications do
        @store.exist? 'the smiths'
      end

      exist = @events.first
      exist.name.should == 'cache_exist?.active_support'
      exist.payload.should == { :key => 'the smiths' }
    end

    it 'notifies on #increment' do
      with_notifications do
        @store.increment 'pearl jam'
      end

      increment = @events.first
      increment.name.should == 'cache_increment.active_support'
      increment.payload.should == { :key => 'pearl jam', :amount => 1 }
    end

    it 'notifies on #decrement' do
      with_notifications do
        @store.decrement 'placebo'
      end

      decrement = @events.first
      decrement.name.should == 'cache_decrement.active_support'
      decrement.payload.should == { :key => 'placebo', :amount => 1 }
    end

    it 'should notify on clear' do
      with_notifications do
        @store.clear
      end

      clear = @events.first
      clear.name.should == 'cache_clear.active_support'
      clear.payload.should == { :key => nil }
    end
  end

  private

  def with_notifications
    ActiveSupport::Cache::MonetaStore.instrument = true
    yield
  ensure
    ActiveSupport::Cache::MonetaStore.instrument = false
  end
end

