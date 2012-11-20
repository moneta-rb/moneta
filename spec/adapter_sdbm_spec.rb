# Generated file
require 'helper'

begin
  Juno::Adapters::SDBM.new(:file => File.join(make_tempdir, "adapter_sdbm")).close

  describe "adapter_sdbm" do
    before do
      @store = Juno::Adapters::SDBM.new(:file => File.join(make_tempdir, "adapter_sdbm"))
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
  puts "Test adapter_sdbm not executed: #{ex.message}"
rescue Exception => ex
  puts "Test adapter_sdbm not executed: #{ex.message}"
  #puts "#{ex.backtrace.join("\n")}"
end
