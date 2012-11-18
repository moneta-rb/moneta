require 'gdbm'

module Juno
  class GDBM < Base
    def initialize(options = {})
      raise 'No option :file specified' unless options[:file]
      @store = ::GDBM.new(options[:file])
    end

    def close
      @store.close
      nil
    end
  end
end
