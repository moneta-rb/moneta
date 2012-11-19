require 'helper'

begin
  describe Juno::Sequel do
    def new_store
      Juno::Sequel.new(:db => 'sqlite:/')
    end

    class_eval(&Juno::Specification)
  end
end
