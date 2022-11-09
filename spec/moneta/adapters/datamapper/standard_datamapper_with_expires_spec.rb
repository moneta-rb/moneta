describe "standard_datamapper_with_expires", unsupported: defined?(JRUBY_VERSION) || RUBY_ENGINE == 'ruby' && Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.0.0'), adapter: :DataMapper, mysql: true do
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
      setup: "mysql://#{mysql_username}:#{mysql_password}@#{mysql_host}:#{mysql_port}/#{mysql_database1}" + (mysql_socket ? "?socket=#{mysql_socket}" : ""),
      table: "simple_datamapper_with_expires",
      expires: true
    }
  end

  moneta_loader do |value|
    ::Marshal.load(value.unpack('m').first)
  end

  moneta_specs STANDARD_SPECS.without_increment.with_expires
end
