module Moneta
  # Proxy base class
  # @api public
  class Proxy
    include Defaults

    attr_reader :adapter

    # @param [Moneta store] adapter underlying adapter
    # @param [Hash] options
    def initialize(adapter, options = {})
      @adapter = adapter
    end

    # (see Defaults#key?)
    def key?(key, options = {})
      adapter.key?(key, options)
    end

    # (see Defaults#increment)
    def increment(key, amount = 1, options = {})
      adapter.increment(key, amount, options)
    end

    # (see Defaults#create)
    def create(key, value, options = {})
      adapter.create(key, value, options)
    end

    # (see Defaults#close)
    def close
      adapter.close
    end

    # Fetch value with key. Return nil if the key doesn't exist
    #
    # @param [Object] key
    # @param [Hash] options
    # @option options [Integer] :expires Update expiration time (See {Expires})
    # @option options [Boolean] :raw Raw access without value transformation (See {Transformer})
    # @option options [String] :prefix Prefix key (See {Transformer})
    # @option options [Boolean] :sync Synchronized load ({Cache} reloads from adapter, {Adapters::Daybreak} syncs with file)
    # @option options Other options as defined by the adapters or middleware
    # @return [Object] value
    # @api public
    def load(key, options = {})
      adapter.load(key, options)
    end

    # Store value with key
    #
    # @param [Object] key
    # @param [Object] value
    # @param [Hash] options
    # @option options [Integer] :expires Set expiration time (See {Expires})
    # @option options [Boolean] :raw Raw access without value transformation (See {Transformer})
    # @option options [String] :prefix Prefix key (See {Transformer})
    # @option options Other options as defined by the adapters or middleware
    # @return value
    # @api public
    def store(key, value, options = {})
      adapter.store(key, value, options)
    end

    # Delete the key from the store and return the current value
    #
    # @param [Object] key
    # @return [Object] current value
    # @param [Hash] options
    # @option options [Boolean] :raw Raw access without value transformation (See {Transformer})
    # @option options [String] :prefix Prefix key (See {Transformer})
    # @option options Other options as defined by the adapters or middleware
    # @api public
    def delete(key, options = {})
      adapter.delete(key, options)
    end

    # Clear all keys in this store
    #
    # @param [Hash] options
    # @return [void]
    # @api public
    def clear(options = {})
      adapter.clear(options)
      self
    end

    # (see Default#features)
    def features
      @features ||= (self.class.features + adapter.features).uniq.freeze
    end
  end
end
