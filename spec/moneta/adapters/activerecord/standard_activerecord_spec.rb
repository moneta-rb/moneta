describe "standard_activerecord", adapter: :ActiveRecord do
  moneta_store :ActiveRecord do
    {
      table: 'standard_activerecord',
      connection: {
        adapter: (defined?(JRUBY_VERSION) ? 'jdbcmysql' : 'mysql2'),
        database: mysql_database1,
        username: mysql_username
      }
    }
  end

  moneta_loader do |value|
    ::Marshal.load(value.unpack('m').first)
  end

  moneta_specs STANDARD_SPECS
end
