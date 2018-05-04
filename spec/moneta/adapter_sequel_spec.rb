describe 'adapter_sequel' do
  specs = ADAPTER_SPECS

  shared_examples :adapter_sequel do
    context 'with MySQL' do
      moneta_build do
        Moneta::Adapters::Sequel.new(opts.merge(
          db: if defined?(JRUBY_VERSION)
                "jdbc:mysql://localhost/#{mysql_database1}?user=#{mysql_username}"
              else
                "mysql2://#{mysql_username}:@localhost/#{mysql_database1}"
              end
          ))
      end

      moneta_specs specs
    end

    context "with SQLite" do
      moneta_build do
        Moneta::Adapters::Sequel.new(opts.merge(
          db: "#{defined?(JRUBY_VERSION) && 'jdbc:'}sqlite://" + File.join(tempdir, 'adapter_sequel.db')))
      end

      moneta_specs specs.without_concurrent
    end

    context "with Postgres" do
      moneta_build do
        Moneta::Adapters::Sequel.new(opts.merge(
          db: "#{defined?(JRUBY_VERSION) && 'jdbc:'}postgres://localhost/#{postgres_database1}",
          user: postgres_username))
      end

      moneta_specs specs
    end
  end

  context 'with backend optimisations' do
    let(:opts) { {table: "adapter_sequel"} }

    include_examples :adapter_sequel
  end

  context 'without backend optimisations' do
    let(:opts) do
      {
        table: "adapter_sequel",
        noopt: 1
      }
    end

    include_examples :adapter_sequel
  end
end
