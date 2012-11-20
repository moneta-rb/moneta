# Generated file
require 'helper'

begin
  Juno::Adapters::MemcachedDalli.new(:server => "localhost:22122", :namespace => "adapter_memcached_dalli").close

  describe "adapter_memcached_dalli" do
    before do
      @store = Juno::Adapters::MemcachedDalli.new(:server => "localhost:22122", :namespace => "adapter_memcached_dalli")
      @store.clear
    end

    after do
      @store.close.should == nil if @store
    end

    it_should_behave_like 'null_stringkey_stringvalue'
    it_should_behave_like 'store_stringkey_stringvalue'
    it_should_behave_like 'returndifferent_stringkey_stringvalue'
    it_should_behave_like 'expires_stringkey_stringvalue'

  end
rescue LoadError => ex
  puts "Test adapter_memcached_dalli not executed: #{ex.message}"
rescue Exception => ex
  puts "Test adapter_memcached_dalli not executed: #{ex.message}"
  #puts "#{ex.backtrace.join("\n")}"
end
