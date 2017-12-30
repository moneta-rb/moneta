describe "standard_activerecord" do
  moneta_store :ActiveRecord,
                   table: 'standard_activerecord',
                   connection: { adapter: (defined?(JRUBY_VERSION) ? 'jdbcmysql' : 'mysql2'),
                                 database: 'moneta',
                                 username: 'root' }

  moneta_loader do |value|
    ::Marshal.load(value.unpack('m').first)
  end

  moneta_specs STANDARD_SPECS
end
