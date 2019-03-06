describe 'standard_sequel', adapter: :Sequel do
  moneta_store :Sequel do
    {
      db: if defined?(JRUBY_VERSION)
            "jdbc:mysql://localhost/#{mysql_database1}?user=#{mysql_username}"
          else
            "mysql2://#{mysql_username}:@localhost/#{mysql_database1}"
          end,
      table: "simple_sequel"
    }
  end

  moneta_specs STANDARD_SPECS
end
