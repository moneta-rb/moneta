require 'helper'

begin
  describe Juno::GDBM do
    def new_store
      Juno::GDBM.new(:file => File.join(make_tempdir, 'gdbm.db'))
    end

    class_eval(&JunoSpecification)
  end
rescue LoadError => ex
  puts "Juno::GDBM not tested: #{ex.message}"
end
