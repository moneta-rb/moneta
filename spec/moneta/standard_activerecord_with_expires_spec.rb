describe "standard_activerecord_with_expires" do
  let(:t_res) { 0.125 }
  let(:min_ttl) { t_res }
  use_timecop

  moneta_store :ActiveRecord do
    {
      table: 'standard_activerecord_with_expires',
      connection: {
        adapter: (defined?(JRUBY_VERSION) ? 'jdbcmysql' : 'mysql2'),
        database: mysql_database1,
        username: mysql_username
      },
      expires: true
    }
  end


  moneta_loader do |value|
    ::Marshal.load(value.unpack('m').first)
  end

  moneta_specs STANDARD_SPECS.with_expires
end
