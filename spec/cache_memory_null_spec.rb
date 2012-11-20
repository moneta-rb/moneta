# Generated file
require 'helper'

begin

Juno.build do
  use(:Cache) do
    backend(Juno::Adapters::Memory.new)
    cache(Juno::Adapters::Null.new)
  end
end.close

  describe "cache_memory_null" do
    before do
      @store = 
Juno.build do
  use(:Cache) do
    backend(Juno::Adapters::Memory.new)
    cache(Juno::Adapters::Null.new)
  end
end
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
  puts "Test cache_memory_null not executed: #{ex.message}"
rescue Exception => ex
  puts "Test cache_memory_null not executed: #{ex.message}"
  #puts "#{ex.backtrace.join("\n")}"
end
