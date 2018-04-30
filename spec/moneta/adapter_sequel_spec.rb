describe 'adapter_sequel' do
  specs = ADAPTER_SPECS

  context 'with MySQL' do
    moneta_build do
      Moneta::Adapters::Sequel.new(
        db: if defined?(JRUBY_VERSION)
              "jdbc:mysql://localhost/#{mysql_database1}?user=#{mysql_username}"
            else
              "mysql2://#{mysql_username}:@localhost/#{mysql_database1}"
            end,
        table: "adapter_sequel")
    end

    moneta_specs specs
  end

  context "with SQLite" do
    moneta_build do
      Moneta::Adapters::Sequel.new(
        db: "#{defined?(JRUBY_VERSION) && 'jdbc:'}sqlite://" + File.join(tempdir, 'adapter_sequel.db'),
        table: "adapter_sequel")
    end

    moneta_specs specs.without_concurrent
  end

  context "with Postgres" do
    moneta_build do
      Moneta::Adapters::Sequel.new(
        db: "#{defined?(JRUBY_VERSION) && 'jdbc:'}postgres://localhost/#{postgres_database1}",
        user: postgres_username,
        table: "adapter_sequel")
    end

    moneta_specs specs
  end
end
