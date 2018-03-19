describe 'adapter_activerecord' do
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

  moneta_build do
    Moneta::Adapters::ActiveRecord.new(
      table: 'adapter_activerecord',
      connection: connection1)
  end

  moneta_specs ADAPTER_SPECS.with_each_key

  it 'updates an existing key/value' do
    store['foo/bar'] = '1'
    store['foo/bar'] = '2'
    store.table.where(k: 'foo/bar').count.should == 1
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
