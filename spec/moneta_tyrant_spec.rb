require File.dirname(__FILE__) + '/spec_helper'

begin
  require "moneta/tyrant"

  describe "Moneta::Tyrant" do
    before(:each) do
      @cache = Moneta::Tyrant.new(:host => "localhost", :port => 1978)
      @cache.clear
    end
  
    it_should_behave_like "a read/write Moneta cache"
  end
rescue SystemExit
end