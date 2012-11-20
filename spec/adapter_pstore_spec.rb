# Generated file
require 'helper'

begin
  Juno::Adapters::PStore.new(:file => File.join(make_tempdir, "adapter_pstore")).close

  describe "adapter_pstore" do
    before do
      @store = Juno::Adapters::PStore.new(:file => File.join(make_tempdir, "adapter_pstore"))
      @store.clear
    end

    after do
      @store.close.should == nil if @store
    end

    it_should_behave_like 'null_stringkey_stringvalue'
    it_should_behave_like 'store_stringkey_stringvalue'
    it_should_behave_like 'returndifferent_stringkey_stringvalue'
    it_should_behave_like 'null_stringkey_objectvalue'
    it_should_behave_like 'store_stringkey_objectvalue'
    it_should_behave_like 'returndifferent_stringkey_objectvalue'

  end
rescue LoadError => ex
  puts "Test adapter_pstore not executed: #{ex.message}"
rescue Exception => ex
  puts "Test adapter_pstore not executed: #{ex.message}"
  #puts "#{ex.backtrace.join("\n")}"
end
