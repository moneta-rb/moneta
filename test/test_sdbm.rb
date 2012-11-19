require 'helper'

begin
  describe Juno::SDBM do
    def new_store
      Juno::GDBM.new(:file => File.join(make_tempdir, 'gdbm.db'))
    end

    class_eval(&Juno::Specification)
  end
rescue LoadError => ex
  puts "Juno::SDBM not tested: #{ex.message}"
end
