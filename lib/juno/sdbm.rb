require 'sdbm'

module Juno
  class SDBM < Base
    def initialize(options = {})
      raise 'No option :file specified' unless options[:file]
      @store = ::SDBM.new(options[:file])
    end

    def close
      @store.close
      nil
    end
  end
end
