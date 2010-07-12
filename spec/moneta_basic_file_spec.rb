require 'spec_helper'

begin
  require "moneta/adapters/basic_file"

  describe "Moneta::Adapters::BasicFile" do
    describe "without namespacing" do
      before(:each) do
        @cache = Moneta::Builder.build do
          run Moneta::Adapters::BasicFile, :path => File.expand_path("../basic_file_cache", __FILE__)
        end
        @cache.clear
      end
      
      if ENV['MONETA_TEST'].nil? || ENV['MONETA_TEST'] == 'basic_file'
        it_should_behave_like "a read/write Moneta cache"
      end
      
      it "should deal with '/' and '#' in a key" do
        key = "hello/mom#crazycharacters"
        @cache[key] = "hi"
        @cache[key].should == "hi"
        ::File.exists?(File.join(File.dirname(__FILE__), "basic_file_cache", "")).should == true
      end
    end
    
    describe "with namespacing" do
      before(:each) do
        @cache = Moneta::Builder.build do
          run Moneta::Adapters::BasicFile, 
            :path => File.expand_path("../basic_file_cache", __FILE__),
            :namespace => "test_namespace"
        end
        
        @cache.clear
      end
      
      if ENV['MONETA_TEST'].nil? || ENV['MONETA_TEST'] == 'basic_file'
        it_should_behave_like "a read/write Moneta cache"
      end
      
      it "should act as two stores within the same directory" do
        @second = Moneta::Builder.build do
          run Moneta::Adapters::BasicFile, 
            :path => File.expand_path("../basic_file_cache", __FILE__),
            :namespace => "second_namespace"
        end
        
        @second[:key] = "hello"
        @cache[:key] = "world!"
        @second[:key].should == "hello"
        @cache[:key].should == "world!"
      end
    end

    after(:all) do
      FileUtils.rm_rf(File.join(File.dirname(__FILE__), "basic_file_cache"))
    end
    
  end
rescue SystemExit
end