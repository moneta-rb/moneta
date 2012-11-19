require 'helper'

describe Juno::Stack do
  def new_store
    Juno::Stack.new(Juno::File.new(:dir => File.join(make_tempdir, 'file')),
                    Juno::Null.new, Juno::Memory.new)
  end

  class_eval(&Juno::Specification)
end
