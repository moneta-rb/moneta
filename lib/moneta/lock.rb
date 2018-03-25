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

    def wrap(name, *args, &block)
      # Other methods (e.g. each_key) may need to call into #supports?; and
      # support is not supposed to change once a class is instantiated, so
      # locking is not necessary.
      if name == :features
        block.call
      else
        @lock.synchronize(&block)
      end
    end
  end
end
