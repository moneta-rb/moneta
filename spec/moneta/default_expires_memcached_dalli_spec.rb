# Generated by generate.rb
require 'helper'

describe_moneta "default_expires_memcached_dalli" do
  def new_store
    Moneta::Adapters::MemcachedDalli.new(:expires => 1)
  end

  def load_value(value)
    Marshal.load(value)
  end

  include_context 'setup_store'
  it_should_behave_like 'default_expires'
end
