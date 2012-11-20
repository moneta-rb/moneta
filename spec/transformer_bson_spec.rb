# Generated file
require 'helper'

begin

Juno.build do
  use :Transformer, :key => :bson, :value => :bson
  adapter :Memory
end.close

  describe "transformer_bson" do
    before do
      @store = 
Juno.build do
  use :Transformer, :key => :bson, :value => :bson
  adapter :Memory
end
      @store.clear
    end

    after do
      @store.close.should == nil if @store
    end

    it_should_behave_like 'null_hashkey_hashvalue'
    it_should_behave_like 'null_hashkey_stringvalue'
    it_should_behave_like 'null_stringkey_hashvalue'
    it_should_behave_like 'null_stringkey_stringvalue'
    it_should_behave_like 'store_hashkey_hashvalue'
    it_should_behave_like 'store_hashkey_stringvalue'
    it_should_behave_like 'store_stringkey_hashvalue'
    it_should_behave_like 'store_stringkey_stringvalue'
    it_should_behave_like 'returndifferent_hashkey_hashvalue'
    it_should_behave_like 'returndifferent_hashkey_stringvalue'
    it_should_behave_like 'returndifferent_stringkey_hashvalue'
    it_should_behave_like 'returndifferent_stringkey_stringvalue'

  end
rescue LoadError => ex
  puts "Test transformer_bson not executed: #{ex.message}"
rescue Exception => ex
  puts "Test transformer_bson not executed: #{ex.message}"
  #puts "#{ex.backtrace.join("\n")}"
end
