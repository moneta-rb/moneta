require File.dirname(__FILE__) + '/spec_helper'

begin
  require "moneta/file"

  describe "Moneta::File" do
    before(:each) do
      @cache = Moneta::File.new(:path => File.join(File.dirname(__FILE__), "file_cache"))
      @cache.clear
    end

    after(:all) do
      FileUtils.rm_rf(File.join(File.dirname(__FILE__), "file_cache"))
    end

    if ENV['MONETA_TEST'].nil? || ENV['MONETA_TEST'] == 'file'
      it_should_behave_like "a read/write Moneta cache"
    end
  end
rescue SystemExit
end