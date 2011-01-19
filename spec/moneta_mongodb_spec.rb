require File.dirname(__FILE__) + '/spec_helper'

begin
  require "moneta/adapters/mongodb"

  describe "Moneta::Adapters::MongoDB" do
    before(:each) do
      @cache = Moneta::Adapters::MongoDB.new
      @cache.clear
    end

    it_should_behave_like "a read/write Moneta cache"

    describe '#store' do
      it 'should store marshalled data that contains "invalid" UTF-8 characters' do
        expect { @cache['example'] = 17.8 }.
          should_not raise_error
      end
    end
  end
rescue SystemExit
end
