describe 'weak_increment', proxy: :WeakIncrement do
  before :all do
    require 'fog/aws'

    # Put Fog into testing mode
    Fog.mock!
  end

  moneta_build do
    Moneta.build do
      use :WeakIncrement
      adapter :Fog,
              aws_access_key_id: 'fake_access_key_id',
              aws_secret_access_key:  'fake_secret_access_key',
              provider:               'AWS',
              dir:                    'weak_increment'
    end
  end

  moneta_specs ADAPTER_SPECS.without_create.without_concurrent.returnsame
end
