require 'helper'

begin
  describe Juno::Sequel do
    def new_store
      Juno::Sequel.new(:db => (defined?(JRUBY_VERSION) ? 'jdbc:sqlite:/' : 'sqlite:/'))
    end

    class_eval(&Juno::Specification)
  end
rescue LoadError => ex
  puts "Juno::Sequel not tested: #{ex.message}"
end
