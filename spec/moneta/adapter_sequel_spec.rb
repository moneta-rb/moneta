describe 'adapter_sequel' do
  moneta_build do
    Moneta::Adapters::Sequel.new(
      db: if defined?(JRUBY_VERSION)
            "jdbc:mysql://localhost/#{mysql_database1}?user=#{mysql_username}"
          else
            "mysql2://#{mysql_username}:@localhost/#{mysql_database1}"
          end,
      table: "adapter_sequel")
  end

  moneta_specs ADAPTER_SPECS
end
