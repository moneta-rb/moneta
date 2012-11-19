require 'helper'

describe Juno::HashFile do
  def new_store
    Juno::HashFile.new(:dir => File.join(make_tempdir, 'hashfile'))
  end

  class_eval(&Juno::Specification)
end
