require 'helper'

begin
  describe Juno::DBM do
    def new_store
      Juno::DBM.new(:file => File.join(make_tempdir, 'dbm.db'))
    end

    class_eval(&Juno::Specification)
  end
rescue LoadError => ex
  puts "Juno::DBM not tested: #{ex.message}"
end
