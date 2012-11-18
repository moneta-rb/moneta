require 'helper'

describe Juno::Expires do
  def new_store
    Juno::Expires.new(Juno::Memory.new)
  end

  class_eval(&JunoSpecification)
  class_eval(&JunoExpiresSpecification)
end
