require File.dirname(__FILE__) + '/spec_helper'

begin
  require "moneta/basic_file"

  describe "Moneta::BasicFile" do
    describe "without namespacing" do
      before(:each) do
        @cache = Moneta::BasicFile.new(:path => File.join(File.dirname(__FILE__), "basic_file_cache"))
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
        @cache = Moneta::BasicFile.new(:path => File.join(File.dirname(__FILE__), "basic_file_cache"), :namespace => "test_namespace")
        @cache.clear
      end
      
      if ENV['MONETA_TEST'].nil? || ENV['MONETA_TEST'] == 'basic_file'
        it_should_behave_like "a read/write Moneta cache"
      end
      
      it "should act as two stores within the same directory" do
        @second = Moneta::BasicFile.new(:path => File.join(File.dirname(__FILE__), "basic_file_cache"), :namespace => "second_namespace")
        @second[:key] = "hello"
        @cache[:key] = "world!"
        @second[:key].should == "hello"
        @cache[:key].should == "world!"
      end
    end

    describe "without expires" do
      before(:each) do
        @cache = Moneta::BasicFile.new(:path => File.join(File.dirname(__FILE__), "basic_file_cache"), :skip_expires => true)
        @cache.clear
      end

      it "should read and write values" do
        @cache[:foo] = 'bar'
        @cache[:foo].should == 'bar'
      end
    end

    after(:all) do
      FileUtils.rm_rf(File.join(File.dirname(__FILE__), "basic_file_cache"))
    end
    
  end
rescue SystemExit
end