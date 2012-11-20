# Generated file
require 'helper'

begin
  Juno::Adapters::Sequel.new(:db => (defined?(JRUBY_VERSION) ? 'jdbc:sqlite:/' : 'sqlite:/')).close

  describe "adapter_sequel" do
    before do
      @store = Juno::Adapters::Sequel.new(:db => (defined?(JRUBY_VERSION) ? 'jdbc:sqlite:/' : 'sqlite:/'))
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
  puts "Test adapter_sequel not executed: #{ex.message}"
rescue Exception => ex
  puts "Test adapter_sequel not executed: #{ex.message}"
  #puts "#{ex.backtrace.join("\n")}"
end
