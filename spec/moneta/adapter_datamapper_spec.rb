describe 'adapter_datamapper' do
  before :all do
    require 'dm-core'

    # DataMapper needs default repository to be setup
    DataMapper.setup(:default, adapter: :in_memory)
  end
  
  moneta_build do
    Moneta::Adapters::DataMapper.new(setup: "mysql://root:@localhost/moneta", table: "adapter_datamapper")
  end

  moneta_specs ADAPTER_SPECS.without_increment
    
  it 'does not cross contaminate when storing' do
    first = Moneta::Adapters::DataMapper.new(setup: "mysql://root:@localhost/moneta", table: "datamapper_first")
    first.clear

    second = Moneta::Adapters::DataMapper.new(repository: :sample, setup: "mysql://root:@localhost/moneta", table: "datamapper_second")
    second.clear

    first['key'] = 'value'
    second['key'] = 'value2'

    first['key'].should == 'value'
    second['key'].should == 'value2'
  end

  it 'does not cross contaminate when deleting' do
    first = Moneta::Adapters::DataMapper.new(setup: "mysql://root:@localhost/moneta", table: "datamapper_first")
    first.clear

    second = Moneta::Adapters::DataMapper.new(repository: :sample, setup: "mysql://root:@localhost/moneta", table: "datamapper_second")
    second.clear

    first['key'] = 'value'
    second['key'] = 'value2'

    first.delete('key').should == 'value'
    first.key?('key').should be false
    second['key'].should == 'value2'
  end
end
