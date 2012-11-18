require 'helper'

begin
  describe Juno::Cassandra do
    def new_store
      Juno::Cassandra.new
    end

    class_eval(&JunoSpecification)
  end
rescue LoadError => ex
  puts "Juno::Cassandra not tested: #{ex.message}"
end
