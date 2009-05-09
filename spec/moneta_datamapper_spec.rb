require File.dirname(__FILE__) + '/spec_helper'

begin
  require "moneta/datamapper"
  
  describe "Moneta::DataMapper" do

    describe "default repository" do
      before(:each) do
        @cache = Moneta::DataMapper.new(:setup => "sqlite3::memory:")
        @cache.clear
      end
  
      after(:all) do
        repository(:moneta) { MonetaHash.auto_migrate! }
      end

      it_should_behave_like "a read/write Moneta cache"
    end

    describe "when :repository specified" do
      before(:each) do
        @cache = Moneta::DataMapper.new(:repository => :sample, :setup => "sqlite3::memory:")
        @cache.clear
      end

      after(:all) do
        repository(:sample) { MonetaHash.auto_migrate! }
      end

      it_should_behave_like "a read/write Moneta cache"
    end

    describe "with multple stores" do
      before(:each) do
        @default_cache = Moneta::DataMapper.new(:setup => "sqlite3:moneta.db")
        @default_cache.clear

        @sample_cache = Moneta::DataMapper.new(:repository => :sample, :setup => "sqlite3:sample.db")
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

      it "does not cross contaminate when expiring" do
        @default_cache.store("key", "value", :expires_in => 2)
        @sample_cache["key"] = "value2"

        time = Time.now
        Time.stub!(:now).and_return { time + 2 }

        @default_cache["key"].should == nil
        @sample_cache["key"].should == "value2"
      end
    end
  end
rescue SystemExit
end