# Generated file
require 'helper'

begin

Juno.build do
  use :Transformer, :value => :compress
  adapter :Memory
end.close

  describe "transformer_compress" do
    before do
      @store = 
Juno.build do
  use :Transformer, :value => :compress
  adapter :Memory
end
      @store.clear
    end

    after do
      @store.close.should == nil if @store
    end

    it_should_behave_like 'null_objectkey_stringvalue'
    it_should_behave_like 'null_stringkey_stringvalue'
    it_should_behave_like 'null_hashkey_stringvalue'
    it_should_behave_like 'store_objectkey_stringvalue'
    it_should_behave_like 'store_stringkey_stringvalue'
    it_should_behave_like 'store_hashkey_stringvalue'
    it_should_behave_like 'returndifferent_objectkey_stringvalue'
    it_should_behave_like 'returndifferent_stringkey_stringvalue'
    it_should_behave_like 'returndifferent_hashkey_stringvalue'

  end
rescue LoadError => ex
  puts "Test transformer_compress not executed: #{ex.message}"
rescue Exception => ex
  puts "Test transformer_compress not executed: #{ex.message}"
  #puts "#{ex.backtrace.join("\n")}"
end
