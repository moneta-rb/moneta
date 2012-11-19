require 'helper'

begin
  describe Juno::ActiveRecord do
    def activerecord_adapter
      defined?(JRUBY_VERSION) ? 'jdbcsqlite3' : 'sqlite3'
    end

    describe 'with connection option set' do
      def new_store
        Juno::ActiveRecord.new(:connection => { :adapter => activerecord_adapter, :database => File.join(make_tempdir, 'db.sqlite3')})
      end

      class_eval(&Juno::Specification)

      it 'updates an existing key/value' do
        @store['foo/bar'] = 4
        @store['foo/bar'] += 4
        records = @store.table.find :all, :conditions => { :key => 'foo/bar' }
        records.count.must_equal 1
      end
    end

    describe 'using preexisting ActiveRecord connection' do
      include Helper

      it 'uses an existing connection' do
        ActiveRecord::Base.establish_connection :adapter => activerecord_adapter, :database => File.join(make_tempdir, 'db.sqlite3')

        store = Juno::ActiveRecord.new
        store.table.table_exists?.must_equal true
      end
    end
  end
rescue LoadError => ex
  puts "Juno::ActiveRecord not tested: #{ex.message}"
end
