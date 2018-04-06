describe "standard_activerecord_with_expires" do
  let(:t_res){ 0.1 }
  let(:min_ttl){ t_res }

  moneta_store :ActiveRecord,
                   table: 'standard_activerecord_with_expires',
                   connection: { adapter: (defined?(JRUBY_VERSION) ? 'jdbcmysql' : 'mysql2'),
                                 database: 'moneta', username: 'root' },
                   expires: true

  moneta_loader do |value|
    ::Marshal.load(value.unpack('m').first)
  end

  moneta_specs STANDARD_SPECS.with_expires
end
