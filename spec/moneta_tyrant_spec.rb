require 'spec_helper'

begin
  require "moneta/adapters/tyrant"

  describe "Moneta::Adapters::Tyrant" do
    before(:each) do
      @cache = Moneta::Adapters::Tyrant.new(:host => "127.0.0.1", :port => 1978)
      @cache.clear
    end

    it_should_behave_like "a read/write Moneta cache"
  end
rescue SystemExit
end
