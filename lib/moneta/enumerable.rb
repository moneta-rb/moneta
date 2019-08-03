module Moneta
  # Adds the Ruby {Enumerable} API to the store.  The underlying store must
  # support `:each_key`.
  #
  # @example Adding to a builder
  #   Moneta.build do
  #     # It should be the top middleware
  #     use :Enumerable
  #     adapter :DBM
  #   end
  #
  # @api public
  class Enumerable < Proxy
    include ::Enumerable

    def initialize(adapter, options = {})
      raise "Adapter must support :each_key" unless adapter.supports? :each_key
      super
    end

    # Enumerate over all pairs in the store
    #
    # @overload each
    #   @return [Enumerator]
    #
    # @overload each
    #   @yieldparam pair [Array<(Object, Object)>] Each pair is yielded
    #   @return [self]
    #
    def each
      return enum_for(:each) unless block_given?
      each_key { |key| yield key, load(key) }
      self
    end

    alias each_pair each
  end
end
