require 'spec_helper'

begin
  require 'moneta/adapters/berkeley'
  require 'bdb/environment'

  describe "Moneta::Adapters::Berkeley" do
    path = File.expand_path("../berkeley_test.db", __FILE__)

    before(:each) do
      @cache = Moneta::Builder.build do
        run Moneta::Adapters::Berkeley, :file => path
      end
      @cache.clear
    end

    after(:all) do
      Moneta::Adapters::Berkeley.close_all
      File.delete(path)
    end

    it_should_behave_like "a read/write Moneta cache"
  end

rescue SystemExit
end