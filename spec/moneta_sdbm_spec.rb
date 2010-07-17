require 'spec_helper'

begin
  require "moneta/adapters/sdbm"

  path = File.expand_path("../sdbm_cache", __FILE__)

  describe "Moneta::Adapters::SDBM" do
    before(:each) do
      @cache = Moneta::Adapters::SDBM.new(:file => path)
      @cache.clear
    end
  
    after(:all) do
      FileUtils.rm_rf(Dir["#{path}*"])
    end
  
    if ENV['MONETA_TEST'].nil? || ENV['MONETA_TEST'] == 'sdbm'
      it_should_behave_like "a read/write Moneta cache"
    end
  end
rescue SystemExit
end
