describe 'adapter_activerecord' do
  moneta_build do
    Moneta::Adapters::ActiveRecord.new(table: 'adapter_activerecord', connection: { adapter: (defined?(JRUBY_VERSION) ? 'jdbcmysql' : 'mysql2'), database: 'moneta', username: 'root' })
  end

  moneta_specs ADAPTER_SPECS

  it 'updates an existing key/value' do
    store['foo/bar'] = '1'
    store['foo/bar'] = '2'
    store.table.where(k: 'foo/bar').count.should == 1
  end

  it 'supports different tables same database' do
    store1 = Moneta::Adapters::ActiveRecord.new(table: 'adapter_activerecord1', connection: { adapter: (defined?(JRUBY_VERSION) ? 'jdbcmysql' : 'mysql2'), database: 'moneta', username: 'root' })
    store2 = Moneta::Adapters::ActiveRecord.new(table: 'adapter_activerecord2', connection: { adapter: (defined?(JRUBY_VERSION) ? 'jdbcmysql' : 'mysql2'), database: 'moneta', username: 'root' })

    store1['key'] = 'value1'
    store2['key'] = 'value2'
    store1['key'].should == 'value1'
    store2['key'].should == 'value2'

    store1.close
    store2.close
  end

  it 'supports different databases same table' do
    store1 = Moneta::Adapters::ActiveRecord.new(table: 'adapter_activerecord', connection: { adapter: (defined?(JRUBY_VERSION) ? 'jdbcmysql' : 'mysql2'), database: 'moneta_activerecord1', username: 'root' })
    store2 = Moneta::Adapters::ActiveRecord.new(table: 'adapter_activerecord', connection: { adapter: (defined?(JRUBY_VERSION) ? 'jdbcmysql' : 'mysql2'), database: 'moneta_activerecord2', username: 'root' })

    store1['key'] = 'value1'
    store2['key'] = 'value2'
    store1['key'].should == 'value1'
    store2['key'].should == 'value2'

    store1.close
    store2.close
  end
end
