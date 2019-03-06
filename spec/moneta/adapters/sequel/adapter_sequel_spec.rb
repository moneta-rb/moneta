
describe 'adapter_sequel', adapter: :Sequel do
  before :all do
    require 'sequel'
  end

  specs = ADAPTER_SPECS.with_each_key.with_values(:nil)

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
          if defined?(JRUBY_VERSION)
            {db: "jdbc:postgresql://localhost/#{postgres_database1}?user=#{postgres_username}"}
          else
            {
              db: "postgres://localhost/#{postgres_database1}",
              user: postgres_username
            }
          end
        ))
      end

      moneta_specs specs
    end

    context "with H2", unsupported: !defined?(JRUBY_VERSION) do
      moneta_build do
        Moneta::Adapters::Sequel.new(opts.merge(
          db: "jdbc:h2:" + tempdir))
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
        optimize: false
      }
    end

    include_examples :adapter_sequel
  end

  context "with Postgres HStore" do
    moneta_build do
      Moneta::Adapters::Sequel.new(
        if defined?(JRUBY_VERSION)
          {db: "jdbc:postgresql://localhost/#{postgres_database1}?user=#{postgres_username}"}
        else
          {
            db: "postgres://localhost/#{postgres_database1}",
            user: postgres_username
          }
        end.merge(
          table: 'hstore_table1',
          hstore: 'row')
      )
    end

    # Concurrency is too slow, and binary values cannot be stored in an hstore
    moneta_specs specs.without_values(:binary).without_concurrent
  end

  describe 'table creation' do
    let(:conn_str) do
      "#{defined?(JRUBY_VERSION) && 'jdbc:'}sqlite://" + File.join(tempdir, 'adapter_sequel.db')
    end

    let(:backend) do
      Sequel.connect(conn_str)
    end

    let(:table_name) { :adapter_sequel_table_creation }

    before { backend.drop_table?(table_name) }

    shared_examples :create_table do
      it "creates the table" do
        store = new_store
        expect(backend.table_exists?(table_name)).to be true
        expect(backend[table_name].columns).to include(store.key_column, store.value_column)
      end
    end

    shared_examples :table_creation do
      context "with :db parameter" do
        moneta_build do
          Moneta::Adapters::Sequel.new(opts.merge(db: conn_str, table: table_name))
        end

        include_examples :create_table
      end

      context "with :backend parameter" do
        moneta_build do
          Moneta::Adapters::Sequel.new(opts.merge(backend: backend, table: table_name))
        end

        include_examples :create_table
      end
    end

    context 'without :create_table option' do
      context 'with default columns' do
        let(:opts) { {} }
        include_examples :table_creation
      end

      context 'with :key_column option' do
        let(:opts) { {key_column: :some_key} }
        include_examples :table_creation
      end

      context 'with :value_column option' do
        let(:opts) { {value_column: :my_value} }
        include_examples :table_creation
      end
    end

    context 'with :create_table proc' do
      let :opts do
        {
          create_table: lambda do |conn|
            called = true
            conn.create_table? table_name do
              String :k, primary_key: true
              File :v
              Integer :other_col
            end
          end
        }
      end

      include_examples :table_creation
    end

    context 'with :create_table false' do
      moneta_build do
        Moneta::Adapters::Sequel.new(db: conn_str, table: table_name, create_table: false)
      end

      it "doesn't create the table" do
        new_store
        expect(backend.table_exists?(table_name)).to be false
      end
    end
  end
end
