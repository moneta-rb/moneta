require 'helper'

begin
  describe Juno::S3 do
    def new_store
      Juno::S3.new(:aws_access_key_id => ENV['S3_KEY'] || 'mocked',
                   :aws_secret_access_key => ENV['S3_SECRET'] || 'mocked',
                   :namespace => 'TESTING')
    end

    class_eval(&JunoSpecification)
  end
rescue LoadError => ex
  puts "Juno::S3 not tested: #{ex.message}"
end
