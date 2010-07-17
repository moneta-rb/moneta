require 'spec_helper'
require 'fileutils'

begin
  require "moneta/adapters/datamapper"

  DataMapper.setup(:default, :adapter => :in_memory)
  path = File.expand_path("../datamapper_spec.db", __FILE__)
  FileUtils.rm(path) if File.exist?(path)

  describe "Moneta::DataMapper" do

    before(:each) do
      DataMapper.repository(:default).adapter.reset
    end

    describe "with the default repository" do
      before(:each) do
        @cache = Moneta::Adapters::DataMapper.new(:setup => "sqlite3://#{path}")
        @cache.clear
      end

      after(:all) do
        MonetaHash.auto_migrate!(:moneta)
      end

      it_should_behave_like "a read/write Moneta cache"
    end

    describe "when :repository specified" do
      before(:each) do
        @cache = Moneta::Adapters::DataMapper.new(:repository => :sample, :setup => "sqlite3://#{path}")
        @cache.clear
      end

      after(:all) do
        MonetaHash.auto_migrate!(:sample)
      end

      it_should_behave_like "a read/write Moneta cache"
    end

    describe "with multiple stores" do
      before(:each) do
        @default_cache = Moneta::Adapters::DataMapper.new(:setup => "sqlite3:moneta.db")
        @default_cache.clear

        @sample_cache = Moneta::Adapters::DataMapper.new(:repository => :sample, :setup => "sqlite3:sample.db")
        @sample_cache.clear
      end

      after(:all) do
        File.delete('moneta.db')
        File.delete('sample.db')
      end

      # TODO should there be more tests than these?
      it "does not cross contaminate when storing" do
        @default_cache["key"] = "value"
        @sample_cache["key"] = "value2"

        @default_cache["key"].should == "value"
        @sample_cache["key"].should == "value2"
      end

      it "does not cross contaminate when deleting" do
        @default_cache["key"] = "value"
        @sample_cache["key"] = "value2"

        @default_cache.delete("key").should == "value"
        @default_cache.key?("key").should be_false
        @sample_cache["key"].should == "value2"
      end
    end
  end
rescue SystemExit
end
