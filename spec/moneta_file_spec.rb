require 'spec_helper'

begin
  require "moneta/adapters/file"

  describe "Moneta::Adapters::File" do
    before(:each) do
      @cache = Moneta::Builder.build do
        run Moneta::Adapters::File, :path => File.expand_path("../file_cache", __FILE__)
      end
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