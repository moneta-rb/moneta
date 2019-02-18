describe 'standard_fog_with_expires' do
  let(:t_res) { 0.125 }
  let(:min_ttl) { t_res }
  use_timecop

  before :all do
    require 'fog/aws'

    # Put Fog into testing mode
    Fog.mock!
  end

  moneta_store :Fog, {aws_access_key_id:      'fake_access_key_id',
                          aws_secret_access_key:  'fake_secret_access_key',
                          provider:               'AWS',
                          dir:                    'standard_fog_with_expires',
                          expires:                true}

  moneta_specs STANDARD_SPECS.without_increment.without_create.with_expires
end
