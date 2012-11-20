# Generated file
require 'helper'

begin
  require 'riak'

  Riak.disable_list_keys_warnings = true

  Juno::Adapters::Riak.new.close

  describe "adapter_riak" do
    before do
      @store = Juno::Adapters::Riak.new
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
  puts "Test adapter_riak not executed: #{ex.message}"
rescue Exception => ex
  puts "Test adapter_riak not executed: #{ex.message}"
  #puts "#{ex.backtrace.join("\n")}"
end
