require 'spec_helper'

begin
  require "moneta/adapters/pstore"

  describe Moneta::Adapters::PStore do
    path = File.expand_path("../pstore_cache", __FILE__)

    before(:each) do
      @cache = Moneta::Builder.new do
        run Moneta::Adapters::PStore, :path => path
      end
      @cache.clear
    end

    after(:all) do
      FileUtils.rm_rf(path)
    end

    if ENV['MONETA_TEST'].nil? || ENV['MONETA_TEST'] == 'pstore'
      it_should_behave_like "a read/write Moneta cache"
    end
  end
rescue SystemExit
end
