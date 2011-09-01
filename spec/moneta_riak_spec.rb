require File.dirname(__FILE__) + '/spec_helper'

begin
  require "moneta/adapters/riak"

  describe "Moneta::Adapters::Riak" do
    before(:all) do
      @cache = Moneta::Adapters::Riak.new
    end

    before(:each) do
      @cache.clear
    end

    it_should_behave_like "a read/write Moneta cache"
  end
rescue SystemExit
end
