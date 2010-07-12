require File.dirname(__FILE__) + '/spec_helper'

begin
  require "moneta/adapters/yaml"

  describe "Moneta::Adapters::YAML" do
    path = File.expand_path("../yaml_cache", __FILE__)

    before(:each) do
      @cache = Moneta::Builder.new do
        run Moneta::Adapters::YAML, :path => path
      end
      @cache.clear
    end

    after(:all) do
      FileUtils.rm_rf(path)
    end

    if ENV['MONETA_TEST'].nil? || ENV['MONETA_TEST'] == 'yaml'
      it_should_behave_like "a read/write Moneta cache"
    end
  end
rescue SystemExit
end
