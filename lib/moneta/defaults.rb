module Moneta
  # Simple interface to key/value stores with Hash-like interface.
  # @api public
  module Defaults
    include ::Moneta::OptionSupport

    # @api private
    module ClassMethods
      # Returns features list
      #
      # @return [Array<Symbol>] list of features
      def features
        @features ||= superclass.respond_to?(:features) ? superclass.features : [].freeze
      end

      # Declares that this adapter supports the given feature.
      #
      # @example
      #   class MyAdapter
      #     include Moneta::Defaults
      #     supports :create
      #     def create(key, value, options = {})
      #       # implement create!
      #     end
      #   end
      def supports(*features)
        @features = (self.features | features).freeze
      end

      # Declares that this adapter does not support the given feature, and adds
      # a stub method that raises a NotImplementedError.  Useful when inheriting
      # from another adapter.
      #
      # @example
      #   class MyAdapter < OtherAdapterWithCreate
      #     include Moneta::Defaults
      #     not_supports :create
      #   end
      def not_supports(*features)
        features.each do |feature|
          define_method(feature) do
            raise ::NotImplementedError, "#{feature} not supported"
          end
        end

        @features = (self.features - features).freeze
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    # Exists the value with key
    #
    # @param [Object] key
    # @param [Hash] options
    # @option options [Integer] :expires Update expiration time (See {Expires})
    # @option options [String] :prefix Prefix key (See {Transformer})
    # @option options Other options as defined by the adapters or middleware
    # @return [Boolean]
    # @api public
    def key?(key, options = {})
      load(key, options) != nil
    end

    # Atomically increment integer value with key
    #
    # This method also accepts negative amounts.
    #
    # @note Not every Moneta store implements this method,
    #       a NotImplementedError is raised if it is not supported.
    # @param [Object] key
    # @param [Integer] amount
    # @param [Hash] options
    # @option options [String] :prefix Prefix key (See {Transformer})
    # @option options Other options as defined by the adapters or middleware
    # @return [Object] value from store
    # @api public
    def increment(key, amount = 1, options = {})
      raise NotImplementedError, 'increment is not supported'
    end

    # Atomically decrement integer value with key
    #
    # This is just syntactic sugar for calling #increment with a negative value.
    #
    # This method also accepts negative amounts.
    #
    # @param [Object] key
    # @param [Integer] amount
    # @param [Hash] options
    # @option options [String] :prefix Prefix key (See {Transformer})
    # @option options Other options as defined by the adapters or middleware
    # @return [Object] value from store
    # @api public
    def decrement(key, amount = 1, options = {})
      increment(key, -amount, options)
    end

    # Explicitly close the store
    # @return nil
    # @api public
    def close; end

    # Fetch a value with a key
    #
    # @overload fetch(key, options = {}, &block)
    #   retrieve a key. if the key is not available, execute the
    #   block and return its return value.
    #   @param [Object] key
    #   @param [Hash] options
    #   @option options [Integer] :expires Update expiration time (See {Expires})
    #   @option options [Boolean] :raw Raw access without value transformation (See {Transformer})
    #   @option options [String] :prefix Prefix key (See {Transformer})
    #   @return [Object] value from store
    #
    # @overload fetch(key, default, options = {})
    #   retrieve a key. if the key is not available, return the default value.
    #   @param [Object] key
    #   @param [Object] default Default value
    #   @param [Hash] options
    #   @option options [Integer] :expires Update expiration time (See {Expires})
    #   @option options [Boolean] :raw Raw access without value transformation (See {Transformer})
    #   @option options [String] :prefix Prefix key (See {Transformer})
    #   @return [Object] value from store
    #
    # @api public
    def fetch(key, default = nil, options = nil)
      if block_given?
        raise ArgumentError, 'Only one argument accepted if block is given' if options
        result = load(key, default || {})
        result == nil ? yield(key) : result
      else
        result = load(key, options || {})
        result == nil ? default : result
      end
    end

    # Fetch value with key. Return nil if the key doesn't exist
    #
    # @param [Object] key
    # @return [Object] value
    # @api public
    def [](key)
      load(key)
    end

    # Store value with key
    #
    # @param [Object] key
    # @param [Object] value
    # @return value
    # @api public
    def []=(key, value)
      store(key, value)
    end

    # Calls block once for each key in store, passing the key as a parameter. If
    # no block is given, an enumerator is returned instead.
    #
    # @note Not every Moneta store implements this method,
    #       a NotImplementedError is raised if it is not supported.
    #
    # @overload each_key
    #   @return [Enumerator] An all-the-keys enumerator
    #
    # @overload each_key
    #   @yieldparam key [Object] Each key is yielded to the supplied block
    #   @return [self]
    #
    # @api public
    def each_key
      raise NotImplementedError, 'each_key is not supported'
    end

    # Atomically sets a key to value if it's not set.
    #
    # @note Not every Moneta store implements this method,
    #       a NotImplementedError is raised if it is not supported.
    # @param [Object] key
    # @param [Object] value
    # @param [Hash] options
    # @option options [Integer] :expires Update expiration time (See {Expires})
    # @option options [Boolean] :raw Raw access without value transformation (See {Transformer})
    # @option options [String] :prefix Prefix key (See {Transformer})
    # @return [Boolean] key was set
    # @api public
    def create(key, value, options = {})
      raise NotImplementedError, 'create is not supported'
    end

    # Returns an array containing the values associated with the given keys, in
    # the same order as the supplied keys. If a key is not present in the
    # key-value-store, nil is returned in its place.
    #
    # @note Some adapters may implement this method atomically, but the default
    #   implementation simply makes repeated calls to {#load}.
    #
    # @param keys [<Object>] The keys for the values to fetch
    # @param options [Hash]
    # @option options (see Proxy#load)
    # @return [Array<Object, nil>] Array containing the values requested, with
    #   nil for missing values
    # @api public
    def values_at(*keys, **options)
      keys.map { |key| load(key, options) }
    end

    # Behaves identically to {#values_at} except that it accepts an optional
    # block. When supplied, the block will be called successively with each
    # supplied key that is not present in the store.  The return value of the
    # block call will be used in place of nil in returned the array of values.
    #
    # @note Some adapters may implement this method atomically. The default
    #   implmentation uses {#values_at}.
    #
    # @overload fetch_values(*keys, **options)
    #   @param (see #values_at)
    #   @option options (see #values_at)
    #   @return (see #values_at)
    # @overload fetch_values(*keys, **options)
    #   @param (see #values_at)
    #   @option options (see #values_at)
    #   @yieldparam key [Object] Each key that is not found in the store
    #   @yieldreturn [Object, nil] The value to substitute for the missing one
    #   @return [Array<Object, nil>] Array containing the values requested, or
    #     where keys are missing, the return values from the corresponding block
    #     calls
    # @api public
    def fetch_values(*keys, **options)
      values = values_at(*keys, **options)
      return values unless block_given?
      keys.zip(values).map do |key, value|
        if value == nil
          yield key
        else
          value
        end
      end
    end

    # Returns a collection of key-value pairs corresponding to those supplied
    # keys which are present in the key-value store, and their associated
    # values.  Only those keys present in the store will have pairs in the
    # return value.  The return value can be any enumerable object that yields
    # pairs, so it could be a hash, but needn't be.
    #
    # @note The keys in the return value may be the same objects that were
    #   supplied (i.e. {Object#equal?}), or may simply be equal (i.e.
    #   {Object#==}).
    #
    # @note Some adapters may implement this method atomically. The default
    #   implmentation uses {#values_at}.
    #
    # @param (see #values_at)
    # @option options (see #values_at)
    # @return [<(Object, Object)>] A collection of key-value pairs
    # @api public
    def slice(*keys, **options)
      keys.zip(values_at(*keys, **options)).reject do |_, value|
        value == nil
      end
    end

    # Stores the pairs in the key-value store, and returns itself. When a block
    # is provided, it will be called before overwriting any existing values with
    # the key, old value and supplied value, and the return value of the block
    # will be used in place of the supplied value.
    #
    # @note Some adapters may implement this method atomically, or in two passes
    #   when a block is provided. The default implmentation uses {#key?},
    #   {#load} and {#store}.
    #
    # @overload merge!(pairs, options={})
    #   @param [<(Object, Object)>] pairs A collection of key-value pairs to store
    #   @param [Hash] options
    #   @option options (see Proxy#store)
    #   @return [self]
    # @overload merge!(pairs, options={})
    #   @param [<(Object, Object)>] pairs A collection of key-value pairs to store
    #   @param [Hash] options
    #   @option options (see Proxy#store)
    #   @yieldparam key [Object] A key that whose value is being overwritten
    #   @yieldparam old_value [Object] The existing value which is being overwritten
    #   @yieldparam new_value [Object] The value supplied in the method call
    #   @yieldreturn [Object] The value to use for overwriting
    #   @return [self]
    # @api public
    def merge!(pairs, options = {})
      pairs.each do |key, value|
        if block_given?
          existing = load(key, options)
          value = yield(key, existing, value) unless existing == nil
        end
        store(key, value, options)
      end
      self
    end

    # (see #merge!)
    def update(pairs, options = {}, &block)
      merge!(pairs, options, &block)
    end

    # Returns features list
    #
    # @return [Array<Symbol>] list of features
    def features
      self.class.features
    end

    # Return true if adapter supports the given feature.
    #
    # @return [Boolean]
    def supports?(feature)
      features.include?(feature)
    end
  end
end
