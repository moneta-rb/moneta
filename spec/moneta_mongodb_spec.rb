require File.dirname(__FILE__) + '/spec_helper'

begin
  require "moneta/adapters/mongodb"

  describe "Moneta::Adapters::MongoDB" do
    before(:each) do
      @cache = Moneta::Adapters::MongoDB.new
      @cache.clear
    end

    describe '#initialize' do
      it 'should initialize with a URI' do
        mock_mongo = mock(Object, :db => mock(Object, :collection => []))
        Mongo::Connection.should_receive(:from_uri).
          with('mongodb://a:b@localhost:27059/cache').
          and_return mock_mongo
        m = Moneta::Adapters::MongoDB.new :uri => 'mongodb://a:b@localhost:27059/cache'
      end
      it 'should initialize with a hash of options' do
        m = Moneta::Adapters::MongoDB.new
        m['example'] = 3.0
        m['example'].should == 3.0
      end
    end

    context 'initialized' do
      it_should_behave_like "a read/write Moneta cache"

      describe '#store' do
        it 'should store marshalled data that contains "invalid" UTF-8 characters' do
          expect { @cache['example'] = 17.8 }.
            should_not raise_error
        end
      end
    end
  end
rescue SystemExit
end
