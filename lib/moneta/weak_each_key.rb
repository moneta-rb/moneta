require 'set'

module Moneta
  # Adds weak key enumeration support to the underlying store
  #
  # @note This class wraps methods that store and retrieve entries in order to
  #   track which keys are in the store, and uses this list when doing key
  #   traversal.  This means that {#each_key each_key} will only yield keys
  #   which have been accessed previously via the present store object.  This
  #   wrapper is therefore best suited to adapters which are not persistent, and
  #   which cannot be shared.
  #
  # @api public
  class WeakEachKey < Wrapper
    supports :each_key

    # @param [Moneta store] adapter The underlying store
    # @param [Hash] options
    def initialize(adapter, options = {})
      raise 'Store already supports feature :each_key' if adapter.supports?(:each_key)
      @all_keys = Set.new
      super
    end

    # (see Proxy#each_key)
    def each_key
      return enum_for(:each_key) { all_keys.size } unless block_given?
      all_keys.each { |key| yield key }
      self
    end

    protected

    attr_reader :all_keys

    def wrap(name, *args)
      case name
      when :create, :store, :increment, :create
        each_key_save(args[0])
        yield
      when :key?
        if found = yield
          each_key_save(args[0])
        else
          all_keys.delete(args[0])
        end
        found
      when :load
        key?(*args)
        yield
      when :delete
        all_keys.delete(args[0])
        yield
      when :clear, :close
        all_keys.clear
        yield
      when :values_at, :fetch_values, :slice
        args[0].each { |key| key?(key) }
        yield
      when :merge!
        args[0].each { |key, _| each_key_save(key) }
        yield
      else
        yield
      end
    end

    def each_key_save(key)
      @all_keys = Set.new(@all_keys).add(key)
    end
  end
end
