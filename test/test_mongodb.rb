require 'helper'

begin
  describe Juno::MongoDB do
    def new_store
      Juno::MongoDB.new
    end

    class_eval(&JunoSpecification)
  end
rescue LoadError => ex
  puts "Juno::MongoDB not tested: #{ex.message}"
end
