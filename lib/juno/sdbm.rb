require 'sdbm'

module Juno
  class SDBM < Memory
    def initialize(options = {})
      raise 'No option :file specified' unless options[:file]
      @store = ::SDBM.new(options[:file])
    end

    def close
      @store.close
      nil
    end

    def store(key, value, options = {})
      super
      value
    rescue SDBMError
      # SDBM is not very robust!
      # You shouldn't put to much data into it, otherwise
      # it might raise a SDBMError.
      value
    end
  end
end
