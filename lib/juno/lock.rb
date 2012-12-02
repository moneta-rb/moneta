require 'thread'

module Juno
  class Lock < Proxy
    def initialize(adapter, options = {})
      super
      @lock = Mutex.new
    end

    def key?(key, options = {})
      @lock.synchronize { super }
    end

    def load(key, options = {})
      @lock.synchronize { super }
    end

    def store(key, value, options = {})
      @lock.synchronize { super }
    end

    def delete(key, options = {})
      @lock.synchronize { super }
    end

    def clear(options = {})
      @lock.synchronize { super }
      self
    end

    def close
      @lock.synchronize { super }
    end
  end
end
