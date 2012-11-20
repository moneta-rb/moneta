# Generated file
require 'helper'

begin
  Juno::Adapters::File.new(:dir => File.join(make_tempdir, "adapter_file")).close

  describe "adapter_file" do
    before do
      @store = Juno::Adapters::File.new(:dir => File.join(make_tempdir, "adapter_file"))
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
  puts "Test adapter_file not executed: #{ex.message}"
rescue Exception => ex
  puts "Test adapter_file not executed: #{ex.message}"
  #puts "#{ex.backtrace.join("\n")}"
end
