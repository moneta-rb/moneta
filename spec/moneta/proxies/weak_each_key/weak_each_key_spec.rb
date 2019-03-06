describe 'weak_each_key', proxy: :WeakEachKey do
  before :all do
    require 'fog/aws'

    # Put Fog into testing mode
    Fog.mock!
  end

  moneta_build do
    Moneta.build do
      use :WeakEachKey
      # use :WeakIncrement
      # use :WeakCreate

      adapter :Fog,
              aws_access_key_id: 'fake_access_key_id',
              aws_secret_access_key: 'fake_secret_access_key',
              provider: 'AWS',
              dir: 'weak_each_key'
    end
  end

  moneta_specs ADAPTER_SPECS.with_each_key.without_create.without_increment.without_concurrent.returnsame
end
