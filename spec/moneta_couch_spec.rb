require File.dirname(__FILE__) + '/spec_helper'

begin
  require 'moneta/adapters/couch'

  describe "Moneta::Adapters::Couch" do
    before(:each) do
      @cache = Moneta::Builder.build do
        run Moneta::Adapters::Couch, :db => "couch_test"
      end
      @cache.clear
    end

    it_should_behave_like "a read/write Moneta cache"
  end
rescue SystemExit
end
