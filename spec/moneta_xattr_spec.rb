require 'spec_helper'

begin
  require "moneta/adapters/xattr"

  describe "Moneta::Adapters::Xattr" do
    path = File.expand_path("../file_cache/xattr_cache", __FILE__)

    before(:each) do
      @cache = Moneta::Builder.build do
        run Moneta::Adapters::Xattr, :file => path
      end
      @cache.clear
    end
  
    after(:all) do
      FileUtils.rm_rf(File.dirname(path))
    end
  
    if ENV['MONETA_TEST'].nil? || ENV['MONETA_TEST'] == 'xattrs'
      it_should_behave_like "a read/write Moneta cache"
    end
  end
rescue SystemExit
end