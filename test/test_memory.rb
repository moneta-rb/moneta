require 'helper'

describe Juno::Memory do
  def new_store
    Juno::Memory.new
  end

  class_eval(&Juno::Specification)
end
