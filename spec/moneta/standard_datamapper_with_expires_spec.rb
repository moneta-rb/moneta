describe "standard_datamapper_with_expires", isolate: true do
  let(:t_res){ 0.1 }
  let(:min_ttl){ t_res }

  before :all do
    require 'dm-core'

    # DataMapper needs default repository to be setup
    DataMapper.setup(:default, adapter: :in_memory)
  end

  moneta_store :DataMapper,
                   setup: "mysql://root:@localhost/moneta",
                   table: "simple_datamapper_with_expires",
                   expires: true

  moneta_loader do |value|
    ::Marshal.load(value.unpack('m').first)
  end

  moneta_specs STANDARD_SPECS.without_increment.with_expires
end
