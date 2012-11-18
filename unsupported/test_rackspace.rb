require 'helper'

begin
  describe Juno::Rackspace do
    def new_store
      Juno::Rackspace.new(:rackspace_username => ENV['RACKSPACE_USERNAME'] || 'mocked',
                          :rackspace_api_key => ENV['RACKSPACE_APIKEY'] || 'mocked',
                          :namespace => 'TESTING')
    end

    class_eval(&JunoSpecification)
  end
rescue LoadError => ex
  puts "Juno::Rackspace not tested: #{ex.message}"
end
