require 'helper'

begin
  describe Juno::Sequel do
    def new_store
      store = Juno::Sequel.new(:db => 'sqlite:/')
      store.migrate
      store
    end

    class_eval(&JunoSpecification)
  end
end
