describe "standard_datamapper", broken: defined?(JRUBY_VERSION), adapter: :DataMapper do
  before :all do
    require 'dm-core'

    # DataMapper needs default repository to be setup
    DataMapper.setup(:default, adapter: :in_memory)
  end

  moneta_store :DataMapper do
    {
      setup: "mysql://#{mysql_username}:#{mysql_password}@localhost/#{mysql_database1}",
      table: "simple_datamapper"
    }
  end

  moneta_loader do |value|
    ::Marshal.load(value.unpack('m').first)
  end

  moneta_specs STANDARD_SPECS.without_increment
end
