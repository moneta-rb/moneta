require 'helper'

describe Juno::Proxy do
  def new_store
    Juno::Proxy.new(Juno::Proxy.new(Juno::Memory.new))
  end

  class_eval(&Juno::Specification)
end
