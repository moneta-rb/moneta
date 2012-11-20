# Generated file
require 'helper'

begin

Juno.build do
  use :Expires
  use :Transformer, :key => [:marshal, :escape], :value => :marshal
  adapter :File, :dir => File.join(make_tempdir, "expires-file")
end.close

  describe "expires_file" do
    before do
      @store = 
Juno.build do
  use :Expires
  use :Transformer, :key => [:marshal, :escape], :value => :marshal
  adapter :File, :dir => File.join(make_tempdir, "expires-file")
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
    it_should_behave_like 'returndifferent_objectkey_objectvalue'
    it_should_behave_like 'returndifferent_objectkey_stringvalue'
    it_should_behave_like 'returndifferent_objectkey_hashvalue'
    it_should_behave_like 'returndifferent_stringkey_objectvalue'
    it_should_behave_like 'returndifferent_stringkey_stringvalue'
    it_should_behave_like 'returndifferent_stringkey_hashvalue'
    it_should_behave_like 'returndifferent_hashkey_objectvalue'
    it_should_behave_like 'returndifferent_hashkey_stringvalue'
    it_should_behave_like 'returndifferent_hashkey_hashvalue'
    it_should_behave_like 'marshallable_key'

    it 'should delete expired value in underlying file storage' do
      @store.store('foo', 'bar', :expires => 2)
      @store['foo'].should == 'bar'
      sleep 1
      @store['foo'].should == 'bar'
      sleep 2
      @store['foo'].should == nil
      @store.adapter['foo'].should == nil
      @store.adapter.adapter['foo'].should == nil
    end

  end
rescue LoadError => ex
  puts "Test expires_file not executed: #{ex.message}"
rescue Exception => ex
  puts "Test expires_file not executed: #{ex.message}"
  #puts "#{ex.backtrace.join("\n")}"
end
