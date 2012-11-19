require 'helper'

begin
  describe Juno::Fog do
    def new_store
      Fog.mock!
      Juno::Fog.new(:aws_access_key_id      => 'fake_access_key_id',
                    :aws_secret_access_key  => 'fake_secret_access_key',
                    :provider               => 'AWS',
                    :dir                    => 'juno')
    end

    class_eval(&Juno::Specification)
  end
rescue LoadError => ex
  puts "Juno::Fog not tested: #{ex.message}"
end
