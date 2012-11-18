require 'helper'

begin
  describe Juno::TokyoTyrant do
    def new_store
      Juno::TokyoTyrant.new(:host => '127.0.0.1', :port => 1978)
    end

    class_eval(&JunoSpecification)
  end
rescue LoadError => ex
  puts "Juno::TokyoTyrant not tested: #{ex.message}"
end
