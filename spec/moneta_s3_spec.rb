require 'spec_helper'

begin
  require 'moneta/adapters/s3'

  describe "Moneta::Adapters::S3" do
    before(:each) do
      Fog.mock! unless ENV["S3_KEY"]

      @cache = Moneta::Adapters::S3.new(
        :aws_access_key_id => ENV["S3_KEY"] || "mocked",
        :aws_secret_access_key => ENV["S3_SECRET"] || "mocked",
        :namespace => "TESTING"
      )
      @cache.clear
    end

    it_should_behave_like "a read/write Moneta cache"
  end
rescue SystemExit
end
