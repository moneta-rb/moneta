require 'helper'

begin
  describe Juno::LocalMemCache do
    def new_store
      Juno::LocalMemCache.new(:file => File.join(make_tempdir, 'lmc'))
    end

    class_eval(&Juno::Specification)
  end
rescue LoadError => ex
  puts "Juno::LocalMemCache not tested: #{ex.message}"
end
