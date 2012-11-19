require 'helper'

describe Juno::Null do
  def new_store
    Juno::Null.new
  end

  class_eval(&Juno::NullSpecification)
end
