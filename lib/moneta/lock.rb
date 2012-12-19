require 'thread'

module Moneta
  # Locks the underlying stores with a Mutex
  # @api public
  class Lock < Proxy
    # Constructor
    #
    # @param [Moneta store] adapter The underlying store
    # @param [Hash] options
    #
    # Options:
    # * :mutex - Mutex object (default Mutex.new)
    def initialize(adapter, options = {})
      super
      @lock = options[:mutex] || Mutex.new
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
