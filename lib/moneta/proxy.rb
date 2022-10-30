module Moneta
  # Proxy base class
  # @api public
  class Proxy
    include Defaults
    include Config

    attr_reader :adapter

    # @param [Moneta store] adapter underlying adapter
    # @param [Hash] options
    def initialize(adapter, options = {})
      @adapter = adapter
      configure(**options)
    end

    # (see Defaults#key?)
    def key?(key, options = {})
      adapter.key?(key, options)
    end

    # (see Defaults#each_key)
    def each_key(&block)
      raise NotImplementedError, "each_key is not supported on this proxy" \
        unless supports? :each_key

      return enum_for(:each_key) { adapter.each_key.size } unless block_given?
      adapter.each_key(&block)
      self
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

    # (see Defaults#values_at)
    def values_at(*keys, **options)
      adapter.values_at(*keys, **options)
    end

    # (see Defaults#fetch_values)
    def fetch_values(*keys, **options, &defaults)
      adapter.fetch_values(*keys, **options, &defaults)
    end

    # (see Defaults#slice)
    def slice(*keys, **options)
      adapter.slice(*keys, **options)
    end

    # (see Defaults#merge!)
    def merge!(pairs, options = {}, &block)
      adapter.merge!(pairs, options, &block)
      self
    end

    # (see Defaults#features)
    def features
      @features ||= (self.class.features | adapter.features - self.class.features_mask).freeze
    end

    class << self
      # @api private
      def features_mask
        @features_mask ||= [].freeze
      end

      # (see Defaults::ClassMethods#not_supports)
      def not_supports(*features)
        @features_mask = (features_mask | features).freeze
        super
      end
    end

    # Overrides the default implementation of the config method to:
    #
    # * pass the adapter's config, if this proxy has no configuration of its
    #   own
    # * return a merged configuration, allowing the proxy have precedence over
    #   the adapter
    def config
      unless @proxy_config
        config = super
        adapter_config = adapter.config if adapter.class.include?(Config)

        @proxy_config =
          if config && adapter_config
            adapter_members = adapter_config.members - config.members
            members = config.members + adapter_members
            struct = Struct.new(*members)

            values = config.values + adapter_config.to_h.values_at(*adapter_members)
            struct.new(*values)
          else
            config || adapter_config
          end
      end

      @proxy_config
    end
  end
end
