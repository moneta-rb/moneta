describe "standard_activerecord", adapter: :ActiveRecord, mysql: true, broken: ::Gem::Version.new(RUBY_ENGINE_VERSION) >= ::Gem::Version.new('3.0.0') do
  moneta_store :ActiveRecord do
    {
      table: 'standard_activerecord',
      connection: {
        adapter: (defined?(JRUBY_VERSION) ? 'jdbcmysql' : 'mysql2'),
        host: mysql_host,
        port: mysql_port,
        database: mysql_database1,
        username: mysql_username,
        password: mysql_password
      }
    }
  end

  moneta_loader do |value|
    ::Marshal.load(value.unpack('m').first)
  end

  moneta_specs STANDARD_SPECS.with_each_key
end
