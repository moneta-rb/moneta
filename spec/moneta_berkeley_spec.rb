require File.dirname(__FILE__) + '/spec_helper'

begin
  require 'moneta/berkeley'

  describe "Moneta::Berkeley" do
    before(:each) do
      @cache = Moneta::Berkeley.new(:file => File.join(File.dirname(__FILE__), "berkeley_test.db"))
      @cache.clear
    end
  
    after(:all) do
      File.delete(File.join(File.dirname(__FILE__), "berkeley_test.db"))
      File.delete(File.join(File.dirname(__FILE__), "berkeley_test.db_expiration"))
    end
  
    it_should_behave_like "a read/write Moneta cache"
  end
rescue SystemExit
end