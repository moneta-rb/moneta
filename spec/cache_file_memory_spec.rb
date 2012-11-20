# Generated file
require 'helper'

begin

Juno.build do
  use(:Cache) do
    backend { adapter :File, :dir => File.join(make_tempdir, "cache_file_memory") }
    cache { adapter :Memory }
  end
end.close

  describe "cache_file_memory" do
    before do
      @store = 
Juno.build do
  use(:Cache) do
    backend { adapter :File, :dir => File.join(make_tempdir, "cache_file_memory") }
    cache { adapter :Memory }
  end
end
      @store.clear
    end

    after do
      @store.close.should == nil if @store
    end

    it_should_behave_like 'null_stringkey_stringvalue'
    it_should_behave_like 'store_stringkey_stringvalue'
    it_should_behave_like 'returndifferent_stringkey_stringvalue'

    it 'should store loaded values in cache' do
      @store.backend['foo'] = 'bar'
      @store.cache['foo'].should == nil
      @store['foo'].should == 'bar'
      @store.cache['foo'].should == 'bar'
      @store.backend.delete('foo')
      @store['foo'].should == 'bar'
      @store.delete('foo')
      @store['foo'].should == nil
    end

  end
rescue LoadError => ex
  puts "Test cache_file_memory not executed: #{ex.message}"
rescue Exception => ex
  puts "Test cache_file_memory not executed: #{ex.message}"
  #puts "#{ex.backtrace.join("\n")}"
end
