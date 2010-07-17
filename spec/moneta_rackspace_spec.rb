require 'spec_helper'

begin
  require 'moneta/adapters/rackspace'

  describe "Moneta::Adapters::Rackspace" do
    before(:each) do
      #Fog.mock! unless ENV["RACKSPACE_USERNAME"]

      @cache = Moneta::Adapters::Rackspace.new(
        :rackspace_username => ENV["RACKSPACE_USERNAME"] || "mocked",
        :rackspace_api_key => ENV["RACKSPACE_APIKEY"] || "mocked",
        :namespace => "TESTING"
      )
      @cache.clear
    end

    it_should_behave_like "a read/write Moneta cache"
  end
rescue SystemExit
end
