require 'helper'

describe Juno::Proxy do
  describe 'without expires' do
    def new_store
      Juno::Proxy.new(Juno::Proxy.new(Juno::Memory.new))
    end

    class_eval(&Juno::Specification)
  end

  describe 'with expires' do
    def new_store
      Juno::Proxy.new(Juno::Proxy.new(Juno::Redis.new))
    end

    class_eval(&Juno::ExpiresSpecification)
  end
end
