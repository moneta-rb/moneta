require File.dirname(__FILE__) + '/spec_helper'

begin
  require 'moneta/couch'

  describe "Moneta::Couch" do
    before(:each) do
      @cache = Moneta::Couch.new(:db => "couch_test")
      @expiration = Moneta::Couch.new(:db => "couch_test_expiration", :skip_expires => true)
      @cache.clear
      @expiration.clear
    end

    after(:all) do
      @cache.delete_store
      @expiration.delete_store
    end

    it_should_behave_like "a read/write Moneta cache"
  end
rescue SystemExit
end