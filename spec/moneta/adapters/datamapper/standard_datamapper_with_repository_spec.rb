describe 'standard_datamapper_with_repository', unsupported: defined?(JRUBY_VERSION) || RUBY_ENGINE == 'ruby' && Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.0.0'), adapter: :DataMapper, mysql: true do
  before :all do
    require 'dm-core'

    # DataMapper needs default repository to be setup
    DataMapper.setup(:default, adapter: :in_memory)
  end

  moneta_store :DataMapper do
    {
      repository: :repo,
      setup: "mysql://#{mysql_username}:#{mysql_password}@#{mysql_host}:#{mysql_port}/#{mysql_database1}" + (mysql_socket ? "?socket=#{mysql_socket}" : ""),
      table: "simple_datamapper_with_repository"
    }
  end

  moneta_loader do |value|
    ::Marshal.load(value.unpack1('m'))
  end

  moneta_specs STANDARD_SPECS.without_increment
end
