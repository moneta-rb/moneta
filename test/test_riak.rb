require 'helper'

begin
  describe Juno::Riak do
    def new_store
      Juno::Riak.new
    end

    class_eval(&Juno::Specification)
  end
rescue LoadError => ex
  puts "Juno::Riak not tested: #{ex.message}"
end
