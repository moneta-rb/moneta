require File.dirname(__FILE__) + '/spec_helper'

require "moneta/memory"

describe "Moneta::Memory" do
  before(:each) do
    @cache = Moneta::Memory.new
    @cache.clear
  end

  it_should_behave_like "a read/write Moneta cache"
end
