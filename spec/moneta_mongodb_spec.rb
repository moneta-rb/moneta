require File.dirname(__FILE__) + '/spec_helper'

begin
  require "moneta/mongodb"

  describe "Moneta::MongoDB" do
    before(:each) do
      @native_expires = true
      @cache = Moneta::MongoDB.new
      @cache.clear
    end

    it_should_behave_like "a read/write Moneta cache"
  end
rescue SystemExit
end