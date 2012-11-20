# Generated file
require 'helper'

begin
  require 'fog'
  Fog.mock!
  Juno::Adapters::Fog.new(:aws_access_key_id => 'fake_access_key_id',
    :aws_secret_access_key  => 'fake_secret_access_key',
    :provider               => 'AWS',
    :dir                    => 'juno').close

  describe "adapter_fog" do
    before do
      @store = Juno::Adapters::Fog.new(:aws_access_key_id => 'fake_access_key_id',
    :aws_secret_access_key  => 'fake_secret_access_key',
    :provider               => 'AWS',
    :dir                    => 'juno')
      @store.clear
    end

    after do
      @store.close.should == nil if @store
    end

    it_should_behave_like 'null_stringkey_stringvalue'
    it_should_behave_like 'store_stringkey_stringvalue'
    it_should_behave_like 'returndifferent_stringkey_stringvalue'

  end
rescue LoadError => ex
  puts "Test adapter_fog not executed: #{ex.message}"
rescue Exception => ex
  puts "Test adapter_fog not executed: #{ex.message}"
  #puts "#{ex.backtrace.join("\n")}"
end
