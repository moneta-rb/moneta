require File.dirname(__FILE__) + '/spec_helper'

begin
  require 'moneta/s3'

  describe "Moneta::S3" do
    before(:each) do
      @cache = Moneta::S3.new(
        :access_key_id => ENV['AWS_ACCESS_KEY_ID'], 
        :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY'],
        :bucket => 'moneta_test'
      )
      @cache.clear
    end
  
    it_should_behave_like "a read/write Moneta cache"
  end
rescue SystemExit
end