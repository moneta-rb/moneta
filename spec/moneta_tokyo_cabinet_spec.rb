require 'spec_helper'

begin
  require "moneta/adapters/tokyo_cabinet"

  describe "Moneta::Adapters::TokyoCabinet" do
    before(:each) do
      @cache = Moneta::Adapters::TokyoCabinet.new(:file => File.expand_path("../cache", __FILE__))
      @cache.clear
    end

    after(:each) do
      @cache.close
    end

    it_should_behave_like "a read/write Moneta cache"
  end
rescue SystemExit
end
