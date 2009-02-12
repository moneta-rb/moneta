require File.dirname(__FILE__) + '/spec_helper'

describe "Moneta::Memory" do
  before(:each) do
    @cache = Moneta::Memory.new
    @cache.clear
  end
  
  it_should_behave_like "a read/write Moneta cache"
end

describe "Moneta::Memcache" do
  before(:each) do
    @native_expires = true
    @cache = Moneta::Memcache.new(:server => "localhost:11211", :namespace => "moneta_spec")
    @cache.clear
  end
  
  it_should_behave_like "a read/write Moneta cache"
end

describe "Moneta::File" do
  before(:each) do
    @cache = Moneta::File.new(:path => File.join(File.dirname(__FILE__), "file_cache"))
    @cache.clear
  end

  after(:all) do
    FileUtils.rm_rf(File.join(File.dirname(__FILE__), "file_cache"))
  end
  
  it_should_behave_like "a read/write Moneta cache"
end

describe "Moneta::Xattrs" do
  before(:each) do
    @cache = Moneta::Xattr.new(:file => File.join(File.dirname(__FILE__), "file_cache", "xattr_cache"))
    @cache.clear
  end
  
  after(:all) do
    FileUtils.rm_rf(File.join(File.dirname(__FILE__), "file_cache"))
  end
  
  it_should_behave_like "a read/write Moneta cache"
end

describe "Moneta::DataMapper" do
  before(:each) do
    @cache = Moneta::DataMapper.new(:setup => "sqlite3::memory:")
    @cache.clear
  end
  
  after(:all) do
    MonetaHash.auto_migrate!
  end
  
  it_should_behave_like "a read/write Moneta cache"
end