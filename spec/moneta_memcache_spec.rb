require File.dirname(__FILE__) + '/spec_helper'

if defined?(MemCache)
  require "moneta/adapters/memcache"

  describe "Moneta::Adapters::Memcache" do
    before(:each) do
      @native_expires = true
      @cache = Moneta::Builder.build do
        run Moneta::Adapters::Memcache, :server => "localhost:11211", :namespace => "moneta_spec"
      end
      @cache.clear
    end
  
    it_should_behave_like "a read/write Moneta cache"
  end
end  
