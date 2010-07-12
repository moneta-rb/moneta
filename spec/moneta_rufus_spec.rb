require 'spec_helper'

begin
  require "moneta/adapters/rufus"

  describe "Moneta::Adapters::Rufus" do
    before(:each) do
      @cache = Moneta::Adapters::Rufus.new(:file => "cache")
      @cache.clear
    end
  
    it_should_behave_like "a read/write Moneta cache"
  end
rescue SystemExit
end