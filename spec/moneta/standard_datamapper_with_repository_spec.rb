describe 'standard_datamapper_with_repository' do
  before :all do
    require 'dm-core'

    # DataMapper needs default repository to be setup
    DataMapper.setup(:default, adapter: :in_memory)
  end

  moneta_store :DataMapper,
                   repository: :repo,
                   setup: "mysql://root:@localhost/moneta",
                   table: "simple_datamapper_with_repository"

  moneta_loader do |value|
    ::Marshal.load(value.unpack('m').first)
  end

  moneta_specs STANDARD_SPECS.without_increment
end
