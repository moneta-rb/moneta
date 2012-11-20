# Generated file
require 'helper'

begin
  Juno::Adapters::Null.new.close

  describe "null_adapter" do
    before do
      @store = Juno::Adapters::Null.new
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

  end
rescue LoadError => ex
  puts "Test null_adapter not executed: #{ex.message}"
rescue Exception => ex
  puts "Test null_adapter not executed: #{ex.message}"
  #puts "#{ex.backtrace.join("\n")}"
end
