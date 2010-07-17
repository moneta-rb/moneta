require 'spec_helper'

begin
  require "moneta/adapters/redis"

  describe "Moneta::Adapters::Redis" do
    before(:each) do
      @cache = Moneta::Adapters::Redis.new
      @cache.clear
    end

    it_should_behave_like "a read/write Moneta cache"
  end
rescue SystemExit
end
