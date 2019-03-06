describe 'adapter_fog', adapter: :Fog do
  before :all do
    require 'fog/aws'
    Fog.mock!
  end

  moneta_build do
    Moneta::Adapters::Fog.new(aws_access_key_id: 'fake_access_key_id',
                              aws_secret_access_key:  'fake_secret_access_key',
                              provider:               'AWS',
                              dir:                    'adapter_fog')
  end

  # Fog returns same object in mocking mode (in-memory store)
  moneta_specs ADAPTER_SPECS.without_increment.without_create.returnsame
end
