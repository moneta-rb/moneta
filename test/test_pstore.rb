require 'helper'

describe Juno::PStore do
  def new_store
    Juno::PStore.new(:file => File.join(make_tempdir, 'pstore'))
  end

  class_eval(&JunoSpecification)
end
