describe 'adapter_activerecord_existing_connection', adapter: :ActiveRecord do
  before :all do
    require 'active_record'
  end

  before do
    default_env = ActiveRecord::ConnectionHandling::DEFAULT_ENV.call
    ActiveRecord::Base.configurations = {
      default_env => {
        'adapter' => (defined?(JRUBY_VERSION) ? 'jdbcmysql' : 'mysql2'),
        'database' => mysql_database1,
        'username' => mysql_username,
        'password' => mysql_password
      }
    }

    ActiveRecord::Base.establish_connection
  end

  moneta_build do
    Moneta::Adapters::ActiveRecord.new(table: 'adapter_activerecord_existing_connection')
  end

  moneta_specs ADAPTER_SPECS.with_each_key

  # This is based on
  # https://github.com/jjb/rails/blob/ar-connection-management-guide/guides/source/active_record_connection_management.md
  it "supports use on a forking web server", unsupported: !Process.respond_to?(:fork) do
    store['a'] = 'b'

    # Before forking, the connection pool is disconnected so that the
    # forked processes don't use the same connections.
    ActiveRecord::Base.connection_pool.disconnect!

    pids = 8.times.map do
      Process.fork do
        # Connection is then reestablished in the forked process
        ActiveRecord::Base.establish_connection

        exit 1 unless store['a'] == 'b'

        store[Process.pid.to_s] = '1'
        exit 1 unless store[Process.pid.to_s] == '1'
      end
    end

    pids.each do |pid|
      pid2, status = Process.wait2(pid)
      expect(pid2).to eq pid
      expect(status.exitstatus).to eq 0
    end

    # Check that the stores were all operating on the same DB
    ActiveRecord::Base.establish_connection
    pids.each do |pid|
      expect(store[pid.to_s]).to eq '1'
    end
  end
end
