require File.dirname(__FILE__) + '/spec_helper'

begin
  require "moneta/sdbm"

  describe "Moneta::SDBM" do
    before(:each) do
      @cache = Moneta::SDBM.new(:file => File.join(File.dirname(__FILE__), "sdbm_cache"))
      @cache.clear
    end
  
    after(:all) do
      FileUtils.rm_rf(Dir.glob(File.join(File.dirname(__FILE__), "sdbm_cache*")))
    end
  
    if ENV['MONETA_TEST'].nil? || ENV['MONETA_TEST'] == 'sdbm'
      it_should_behave_like "a read/write Moneta cache"
    end
  end
rescue SystemExit
end