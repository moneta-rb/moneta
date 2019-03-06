describe "standard_datamapper_with_expires", broken: defined?(JRUBY_VERSION), adapter: :DataMapper do
  let(:t_res) { 0.125 }
  let(:min_ttl) { t_res }
  use_timecop

  before :all do
    require 'dm-core'

    # DataMapper needs default repository to be setup
    DataMapper.setup(:default, adapter: :in_memory)
  end

  moneta_store :DataMapper do
    {
      setup: "mysql://#{mysql_username}:#{mysql_password}@localhost/#{mysql_database1}",
      table: "simple_datamapper_with_expires",
      expires: true
    }
  end

  moneta_loader do |value|
    ::Marshal.load(value.unpack('m').first)
  end

  moneta_specs STANDARD_SPECS.without_increment.with_expires
end
