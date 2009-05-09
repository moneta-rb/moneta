require File.dirname(__FILE__) + '/spec_helper'

begin
  require "moneta/rufus"

  describe "Moneta::Rufus" do
    before(:each) do
      @cache = Moneta::Rufus.new(:file => "cache")
      @cache.clear
    end
  
    it_should_behave_like "a read/write Moneta cache"
  end
rescue SystemExit
end