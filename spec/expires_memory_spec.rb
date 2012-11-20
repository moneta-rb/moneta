# Generated file
require 'helper'

begin

Juno.build do
  use :Expires
  adapter :Memory
end.close

  describe "expires_memory" do
    before do
      @store = 
Juno.build do
  use :Expires
  adapter :Memory
end
      @store.clear
    end

    after do
      @store.close.should == nil if @store
    end

    it_should_behave_like 'null_objectkey_objectvalue'
    it_should_behave_like 'null_objectkey_stringvalue'
    it_should_behave_like 'null_objectkey_hashvalue'
    it_should_behave_like 'null_stringkey_objectvalue'
    it_should_behave_like 'null_stringkey_stringvalue'
    it_should_behave_like 'null_stringkey_hashvalue'
    it_should_behave_like 'null_hashkey_objectvalue'
    it_should_behave_like 'null_hashkey_stringvalue'
    it_should_behave_like 'null_hashkey_hashvalue'
    it_should_behave_like 'store_objectkey_objectvalue'
    it_should_behave_like 'store_objectkey_stringvalue'
    it_should_behave_like 'store_objectkey_hashvalue'
    it_should_behave_like 'store_stringkey_objectvalue'
    it_should_behave_like 'store_stringkey_stringvalue'
    it_should_behave_like 'store_stringkey_hashvalue'
    it_should_behave_like 'store_hashkey_objectvalue'
    it_should_behave_like 'store_hashkey_stringvalue'
    it_should_behave_like 'store_hashkey_hashvalue'
    it_should_behave_like 'expires_objectkey_objectvalue'
    it_should_behave_like 'expires_objectkey_stringvalue'
    it_should_behave_like 'expires_objectkey_hashvalue'
    it_should_behave_like 'expires_stringkey_objectvalue'
    it_should_behave_like 'expires_stringkey_stringvalue'
    it_should_behave_like 'expires_stringkey_hashvalue'
    it_should_behave_like 'expires_hashkey_objectvalue'
    it_should_behave_like 'expires_hashkey_stringvalue'
    it_should_behave_like 'expires_hashkey_hashvalue'

  end
rescue LoadError => ex
  puts "Test expires_memory not executed: #{ex.message}"
rescue Exception => ex
  puts "Test expires_memory not executed: #{ex.message}"
  #puts "#{ex.backtrace.join("\n")}"
end
