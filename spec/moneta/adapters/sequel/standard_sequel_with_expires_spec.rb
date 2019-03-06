describe 'standard_sequel_with_expires', adapter: :Sequel do
  let(:t_res) { 0.125 }
  let(:min_ttl) { t_res }
  use_timecop

  moneta_store :Sequel do
    {
      db: if defined?(JRUBY_VERSION)
            "jdbc:mysql://localhost/#{mysql_database1}?user=#{mysql_username}"
          else
            "mysql2://#{mysql_username}:@localhost/#{mysql_database1}"
          end,
      table: "simple_sequel_with_expires",
      expires: true
    }
  end

  moneta_specs STANDARD_SPECS.with_expires
end
