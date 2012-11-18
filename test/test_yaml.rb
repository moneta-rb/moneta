require 'helper'

describe Juno::YAML do
  def new_store
    Juno::YAML.new(:file => File.join(make_tempdir, 'yaml'))
  end

  class_eval(&JunoSpecification)
end
