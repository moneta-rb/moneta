require 'thread'

module Moneta
  # Locks the underlying stores with a Mutex
  # @api public
  class Lock < Wrapper
    # @param [Moneta store] adapter The underlying store
    # @param [Hash] options
    # @option options [String] :mutex (::Mutex.new) Mutex object
    def initialize(adapter, options = {})
      super
      @lock = options[:mutex] || ::Mutex.new
    end

    protected

    def wrap(*args, &block)
      @lock.synchronize(&block)
    end
  end
end
