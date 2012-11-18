require 'helper'

describe Juno::File do
  def new_store
    Juno::File.new(:dir => File.join(make_tempdir, 'file'))
  end

  class_eval(&JunoSpecification)
end
