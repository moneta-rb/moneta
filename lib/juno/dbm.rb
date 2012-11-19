require 'dbm'

module Juno
  class DBM < Memory
    def initialize(options = {})
      raise 'No option :file specified' unless options[:file]
      @store = ::DBM.new(options[:file])
    end

    def close
      @store.close
      nil
    end
  end
end
