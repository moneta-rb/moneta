describe 'standard_fog' do
  before :all do
    require 'fog'

    # Put Fog into testing mode
    Fog.mock!
  end

  moneta_store :Fog, {aws_access_key_id:      'fake_access_key_id',
                          aws_secret_access_key:  'fake_secret_access_key',
                          provider:               'AWS',
                          dir:                    'standard_fog'}

  moneta_specs STANDARD_SPECS.without_increment.without_create
end
