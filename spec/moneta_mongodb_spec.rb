require File.dirname(__FILE__) + '/spec_helper'

begin
  require "moneta/adapters/mongodb"

  describe "Moneta::Adapters::MongoDB" do
    before(:each) do
      @cache = Moneta::Adapters::MongoDB.new
      @cache.clear
    end

    it_should_behave_like "a read/write Moneta cache"
  end
rescue SystemExit
end
