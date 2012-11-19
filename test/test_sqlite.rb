require 'helper'

begin
  describe Juno::Sqlite do
    def new_store
      Juno::Sqlite.new(:file => ':memory:')
    end

    class_eval(&Juno::Specification)
  end
rescue LoadError => ex
  puts "Juno::Sqlite not tested: #{ex.message}"
end
