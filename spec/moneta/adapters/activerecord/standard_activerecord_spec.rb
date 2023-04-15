describe "standard_activerecord", adapter: :ActiveRecord, mysql: true do
  moneta_store :ActiveRecord do
    {
      table: 'standard_activerecord',
      connection: {
        adapter: (defined?(JRUBY_VERSION) ? 'jdbcmysql' : 'mysql2'),
        host: mysql_host,
        port: mysql_port,
        socket: mysql_socket,
        database: mysql_database1,
        username: mysql_username,
        password: mysql_password
      }
    }
  end

  moneta_loader do |value|
    ::Marshal.load(value.unpack1('m'))
  end

  moneta_specs STANDARD_SPECS
end
