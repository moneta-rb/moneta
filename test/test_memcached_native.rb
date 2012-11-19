require 'helper'

begin
  describe Juno::MemcachedNative do
    def new_store
      # HACK: memcached is running on 221122 because of travis-ci
      Juno::MemcachedNative.new(:server => 'localhost:22122', :namespace => 'juno')
    end

    class_eval(&Juno::ExpiresSpecification)
  end
rescue LoadError => ex
  puts "Juno::MemcachedNative not tested: #{ex.message}"
end
