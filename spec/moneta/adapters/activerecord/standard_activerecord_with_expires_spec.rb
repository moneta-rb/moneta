describe "standard_activerecord_with_expires", adapter: :ActiveRecord, mysql: true do
  let(:t_res) { 0.125 }
  let(:min_ttl) { t_res }
  use_timecop

  moneta_store :ActiveRecord do
    {
      table: 'standard_activerecord_with_expires',
      connection: {
        adapter: (defined?(JRUBY_VERSION) ? 'jdbcmysql' : 'mysql2'),
        host: mysql_host,
        port: mysql_port,
        socket: mysql_socket,
        database: mysql_database1,
        username: mysql_username,
        password: mysql_password
      },
      expires: true
    }
  end


  moneta_loader do |value|
    ::Marshal.load(value.unpack1('m'))
  end

  moneta_specs STANDARD_SPECS.with_expires.with_each_key
end
