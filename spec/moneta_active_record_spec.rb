require File.dirname(__FILE__) + '/spec_helper'

begin
  require 'moneta/active_record'

  describe 'Moneta::ActiveRecord' do
    before(:each) do
      @cache = Moneta::ActiveRecord.new(:connection => {
        :adapter  => 'mysql',
        :database => 'reports_test',
        :username => 'root'})
      @cache.clear
    end

    it_should_behave_like "a read/write Moneta cache"
  end
rescue SystemExit
end
