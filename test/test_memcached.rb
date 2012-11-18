require 'helper'

begin
  describe Juno::Memcached do
    def new_store
      # HACK: memcached is running on 221122 because of travis-ci
      Juno::Memcached.new(:server => 'localhost:22122', :namespace => 'juno')
    end

    class_eval(&JunoSpecification)
    class_eval(&JunoExpiresSpecification)
  end
rescue LoadError => ex
  puts "Juno::Memcached not tested: #{ex.message}"
end
