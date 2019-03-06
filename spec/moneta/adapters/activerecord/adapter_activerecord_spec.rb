describe 'adapter_activerecord', adapter: :ActiveRecord do
  activerecord_specs = ADAPTER_SPECS.with_values(:nil).with_each_key

  shared_examples :adapter_activerecord do |specs|
    moneta_build do
      Moneta::Adapters::ActiveRecord.new(
        table: 'adapter_activerecord',
        connection: connection1)
    end


    moneta_specs specs

    it 'updates an existing key/value' do
      store['foo/bar'] = '1'
      store['foo/bar'] = '2'
      store.with_connection do |conn|
        count = conn.select_value \
          store.table.
            where(store.table[:k].eq('foo/bar')).
            project(store.table[:k].count)
        expect(count).to eq 1
      end
    end

    it 'supports different tables same database' do
      store1 = Moneta::Adapters::ActiveRecord.new(
        table: 'adapter_activerecord1',
        connection: connection1)
      store2 = Moneta::Adapters::ActiveRecord.new(
        table: 'adapter_activerecord2',
        connection: connection1)

      store1['key'] = 'value1'
      store2['key'] = 'value2'
      store1['key'].should == 'value1'
      store2['key'].should == 'value2'

      store1.close
      store2.close
    end

    it 'supports different databases same table' do
      store1 = Moneta::Adapters::ActiveRecord.new(
        table: 'adapter_activerecord',
        connection: connection1)
      store2 = Moneta::Adapters::ActiveRecord.new(
        table: 'adapter_activerecord',
        connection: connection2)

      store1['key'] = 'value1'
      store2['key'] = 'value2'
      store1['key'].should == 'value1'
      store2['key'].should == 'value2'

      store1.close
      store2.close
    end
  end

  context "with MySQL" do
    let(:connection1) do
      {
        adapter: (defined?(JRUBY_VERSION) ? 'jdbcmysql' : 'mysql2'),
        database: mysql_database1,
        username: mysql_username
      }
    end

    let(:connection2) do
      {
        adapter: (defined?(JRUBY_VERSION) ? 'jdbcmysql' : 'mysql2'),
        database: mysql_database2,
        username: mysql_username
      }
    end

    include_examples :adapter_activerecord, activerecord_specs
  end

  context "with PostgreSQL" do
    let(:connection1) do
      {
        adapter: (defined?(JRUBY_VERSION) ? 'jdbcpostgresql' : 'postgresql'),
        database: postgres_database1,
        username: postgres_username
      }
    end

    let(:connection2) do
      {
        adapter: (defined?(JRUBY_VERSION) ? 'jdbcpostgresql' : 'postgresql'),
        database: postgres_database2,
        username: postgres_username
      }
    end

    include_examples :adapter_activerecord, activerecord_specs
  end

  context "with SQLite" do
    let(:connection1) do
      {
        adapter: (defined?(JRUBY_VERSION) ? 'jdbcsqlite3' : 'sqlite3'),
        database: File.join(tempdir, 'adapter_activerecord1.db')
      }
    end

    let(:connection2) do
      {
        adapter: (defined?(JRUBY_VERSION) ? 'jdbcsqlite3' : 'sqlite3'),
        database: File.join(tempdir, 'adapter_activerecord2.db')
      }
    end

    include_examples :adapter_activerecord, activerecord_specs.without_concurrent
  end
end
