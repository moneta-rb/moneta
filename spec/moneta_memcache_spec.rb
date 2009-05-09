require File.dirname(__FILE__) + '/spec_helper'

begin
  require "moneta/memcache"

  describe "Moneta::Memcache" do
    before(:each) do
      @native_expires = true
      @cache = Moneta::Memcache.new(:server => "localhost:11211", :namespace => "moneta_spec")
      @cache.clear
    end
  
    it_should_behave_like "a read/write Moneta cache"
  end
rescue SystemExit
end  