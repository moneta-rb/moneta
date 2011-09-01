require File.dirname(__FILE__) + '/spec_helper'

begin
  require 'moneta/adapters/cassandra'

  describe "Moneta::Adapters::Cassandra" do
    before(:each) do
      @cache = Moneta::Adapters::Cassandra.new
      @cache.clear
    end

    it_should_behave_like "a read/write Moneta cache"
  end
rescue SystemExit
end