# Generated file
require 'helper'

begin
  Juno::Adapters::Memcached.new(:server => "localhost:22122", :namespace => "adapter_memcached").close

  describe "adapter_memcached" do
    before do
      @store = Juno::Adapters::Memcached.new(:server => "localhost:22122", :namespace => "adapter_memcached")
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
  puts "Test adapter_memcached not executed: #{ex.message}"
rescue Exception => ex
  puts "Test adapter_memcached not executed: #{ex.message}"
  #puts "#{ex.backtrace.join("\n")}"
end
