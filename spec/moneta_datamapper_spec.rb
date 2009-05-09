require File.dirname(__FILE__) + '/spec_helper'

begin
  require "moneta/datamapper"

  describe "Moneta::DataMapper" do
    before(:each) do
      @cache = Moneta::DataMapper.new(:setup => "sqlite3::memory:")
      @cache.clear
    end
  
    after(:all) do
      MonetaHash.auto_migrate!
    end
  
    it_should_behave_like "a read/write Moneta cache"
  end
rescue SystemExit
end