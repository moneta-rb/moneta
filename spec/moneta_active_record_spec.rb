require File.dirname(__FILE__) + '/spec_helper'

require 'moneta/adapters/active_record'

if defined?(ActiveRecord)
  describe 'Moneta::ActiveRecord' do
    after :all do
      FileUtils.rm_f File.expand_path('../reports_test.sqlite3', File.dirname(__FILE__))
    end

    context 'with connection option set' do
      before(:each) do
        @cache = Moneta::Adapters::ActiveRecord.new(:connection => {
          :adapter  => 'sqlite3',
          :database => 'reports_test.sqlite3'
        })
        @cache.migrate
        @cache.clear
      end

      it_should_behave_like "a read/write Moneta cache"

      it 'updates an existing key/value' do
        @cache['foo/bar'] = 4
        @cache['foo/bar'] += 4
        records = Moneta::Adapters::ActiveRecord::Store.find :all, :conditions => { :key_name => 'foo/bar' }
        records.count.should == 1
      end
    end

    context 'using preexisting ActiveRecord connection' do
      describe '#initialize' do
        it 'uses an existing connection' do
          ActiveRecord::Base.establish_connection :adapter => 'sqlite3',
            :database => 'reports_test.sqlite3'
          
          cache = Moneta::Adapters::ActiveRecord.new
          cache.migrate
          Moneta::Adapters::ActiveRecord::Store.table_exists?.should be_true
        end
      end
    end
  end
end
