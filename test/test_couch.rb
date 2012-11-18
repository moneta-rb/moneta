require 'helper'

begin
  describe Juno::Couch do
    def new_store
      Juno::Couch.new :db => 'juno'
    end

    class_eval(&JunoSpecification)
  end
rescue LoadError => ex
  puts "Juno::Couch not tested: #{ex.message}"
end
