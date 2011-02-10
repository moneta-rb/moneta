require File.dirname(__FILE__) + '/spec_helper'

require 'moneta/adapters/active_record'

if defined?(ActiveRecord)
  describe 'Moneta::ActiveRecord' do
    before(:each) do
      @cache = Moneta::Adapters::ActiveRecord.new(:connection => {
        :adapter  => 'sqlite3',
        :database => 'reports_test.sqlite3'
      })
      @cache.migrate
      @cache.clear
    end
    after :all do
      FileUtils.rm_f File.expand_path('../reports_test.sqlite3', File.dirname(__FILE__))
    end

    it_should_behave_like "a read/write Moneta cache"
  end
end
