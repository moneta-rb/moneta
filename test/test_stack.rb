require 'helper'

describe Juno::File do
  def new_store
    Juno::Stack.new(:stores => [ Juno::File.new(:dir => File.join(make_tempdir, 'file')),
                                 Juno::Null.new, Juno::Memory.new ])
  end

  class_eval(&Juno::Specification)
end
