# Generated file
require 'helper'

begin
  Juno::Adapters::ActiveRecord.new(:connection => { :adapter => (defined?(JRUBY_VERSION) ? 'jdbcsqlite3' : 'sqlite3'), :database => File.join(make_tempdir, 'adapter_activerecord.sqlite3') }).close

  describe "adapter_activerecord" do
    before do
      @store = Juno::Adapters::ActiveRecord.new(:connection => { :adapter => (defined?(JRUBY_VERSION) ? 'jdbcsqlite3' : 'sqlite3'), :database => File.join(make_tempdir, 'adapter_activerecord.sqlite3') })
      @store.clear
    end

    after do
      @store.close.should == nil if @store
    end

    it_should_behave_like 'null_stringkey_stringvalue'
    it_should_behave_like 'store_stringkey_stringvalue'
    it_should_behave_like 'returndifferent_stringkey_stringvalue'

    it 'updates an existing key/value' do
      @store['foo/bar'] = '1'
      @store['foo/bar'] = '2'
      records = @store.table.find :all, :conditions => { :k => 'foo/bar' }
      records.count.should == 1
    end

    it 'uses an existing connection' do
      ActiveRecord::Base.establish_connection :adapter => (defined?(JRUBY_VERSION) ? 'jdbcsqlite3' : 'sqlite3'), :database => File.join(make_tempdir, 'activerecord-existing.sqlite3')

      store = Juno::Adapters::ActiveRecord.new
      store.table.table_exists?.should == true
    end

  end
rescue LoadError => ex
  puts "Test adapter_activerecord not executed: #{ex.message}"
rescue Exception => ex
  puts "Test adapter_activerecord not executed: #{ex.message}"
  #puts "#{ex.backtrace.join("\n")}"
end
