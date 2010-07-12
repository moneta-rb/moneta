require 'spec_helper'

require "moneta/adapters/memory"

describe "Moneta::Adapters::Memory" do
  class EmptyMiddleware
    include Moneta::Middleware
  end

  before(:each) do
    @cache = Moneta::Builder.build do
      run Moneta::Adapters::Memory
    end
    @cache.clear
  end

  it_should_behave_like "a read/write Moneta cache"
end
