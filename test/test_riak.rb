require 'helper'

begin
  describe Juno::Riak do
    def new_store
      Juno::Riak.new
    end

    class_eval(&JunoSpecification)
  end
rescue LoadError => ex
  puts "Juno::Riak not tested: #{ex.message}"
end
