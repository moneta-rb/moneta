module Moneta
  # @api private
  module OptionSupport
    # Return Moneta store with default options or additional proxies
    #
    # @param [Hash] options Options to merge
    # @return [Moneta store]
    #
    # @api public
    def with(options = nil, &block)
      adapter = self
      if block
        builder = Builder.new(&block)
        builder.adapter(adapter)
        adapter = builder.build.last
      end
      options ? OptionMerger.new(adapter, options) : adapter
    end

    # Return Moneta store with default option raw: true
    #
    # @return [OptionMerger]
    # @api public
    def raw
      @raw_store ||=
        begin
          store = with(raw: true, only: [:load, :store, :create, :delete])
          store.instance_variable_set(:@raw_store, store)
          store
        end
    end

    # Return Moneta store with default prefix option
    #
    # @param [String] prefix Key prefix
    # @return [OptionMerger]
    # @api public
    def prefix(prefix)
      with(prefix: prefix, except: :clear)
    end

    # Return Moneta store with default expiration time
    #
    # @param [Integer] expires Default expiration time
    # @return [OptionMerger]
    # @api public
    def expires(expires)
      with(expires: expires, only: [:store, :create, :increment])
    end
  end

  # Simple interface to key/value stores with Hash-like interface.
  # @api public
  module Defaults
    include OptionSupport

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
    def close
    end

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
        if value == nil && !key?(key)
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
      keys.zip(values_at(*keys, **options)).reject do |key, value|
        value.nil? && !key?(key)
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
    def merge!(pairs, options={})
      pairs.each do |key, value|
        if block_given? && key?(key, options)
          existing = load(key, options)
          value = yield(key, existing, value)
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

  # @api private
  module IncrementSupport
    # (see Defaults#increment)
    def increment(key, amount = 1, options = {})
      value = Utils.to_int(load(key, options)) + amount
      store(key, value.to_s, options)
      value
    end

    def self.included(base)
      base.supports(:increment) if base.respond_to?(:supports)
    end
  end

  # This provides an each_key implementation that works in most cases.
  # @api private
  module EachKeySupport
    def each_key
      return enum_for(:each_key) unless block_given?

      if @backend.respond_to?(:each_key)
        @backend.each_key { |key| yield key }
      elsif @backend.respond_to?(:keys)
        if keys = @backend.keys
          keys.each { |key| yield key }
        end
      elsif @backend.respond_to?(:each)
        @backend.each { |key, _| yield key }
      else
        raise ::NotImplementedError, "No enumerable found on backend"
      end

      self
    end

    def self.included(base)
      base.supports(:each_key) if base.respond_to?(:supports)
    end
  end

  # Implements simple create using key? and store.
  #
  # This is sufficient for non-shared stores or if atomicity is not required.
  # @api private
  module CreateSupport
    # (see Defaults#create)
    def create(key, value, options = {})
      if key? key
        false
      else
        store(key, value, options)
        true
      end
    end

    def self.included(base)
      base.supports(:create) if base.respond_to?(:supports)
    end
  end

  # @api private
  module HashAdapter
    attr_reader :backend

    # (see Proxy#key?)
    def key?(key, options = {})
      @backend.has_key?(key)
    end

    # (see Proxy#load)
    def load(key, options = {})
      @backend[key]
    end

    # (see Proxy#store)
    def store(key, value, options = {})
      @backend[key] = value
    end

    # (see Proxy#delete)
    def delete(key, options = {})
      @backend.delete(key)
    end

    # (see Proxy#clear)
    def clear(options = {})
      @backend.clear
      self
    end

    # (see Defaults#values_at)
    def values_at(*keys, **options)
      return super unless @backend.respond_to? :values_at
      @backend.values_at(*keys)
    end

    # (see Defaults#fetch_values)
    def fetch_values(*keys, **options, &defaults)
      return super unless @backend.respond_to? :fetch_values
      defaults ||= {} # prevents KeyError
      @backend.fetch_values(*keys, &defaults)
    end

    # (see Defaults#slice)
    def slice(*keys, **options)
      return super unless @backend.respond_to? :slice
      @backend.slice(*keys)
    end

    # (see Defaults#merge!)
    def merge!(pairs, options={}, &block)
      return super unless method = [:merge!, :update].find do |method|
        @backend.respond_to? method
      end

      hash = Hash === pairs ? pairs : Hash[pairs.to_a]
      case method
      when :merge!
        @backend.merge!(hash, &block)
      when :update
        @backend.update(hash, &block)
      end

      self
    end
  end

  # This mixin handles the calculation of expiration times.
  #
  #
  module ExpiresSupport
    attr_accessor :default_expires

    protected

    # Calculates the time when something will expire.
    #
    # This method considers false and 0 as "no-expire" and every positive
    # number as a time to live in seconds.
    #
    # @param [Hash] options Options hash
    # @option options [0,false,nil,Numeric] :expires expires value given by user
    # @param [0,false,nil,Numeric] default default expiration time
    #
    # @return [false] if it should not expire
    # @return [Time] the time when something should expire
    # @return [nil] if it is not known
    def expires_at(options, default = @default_expires)
      value = expires_value(options, default)
      Numeric === value ? Time.now + value : value
    end

    # Calculates the number of seconds something should last.
    #
    # This method considers false and 0 as "no-expire" and every positive
    # number as a time to live in seconds.
    #
    # @param [Hash] options Options hash
    # @option options [0,false,nil,Numeric] :expires expires value given by user
    # @param [0,false,nil,Numeric] default default expiration time
    #
    # @return [false] if it should not expire
    # @return [Numeric] seconds until expiration
    # @return [nil] if it is not known
    def expires_value(options, default = @default_expires)
      case value = options[:expires]
      when 0, false
        false
      when nil
        default ? default.to_r : nil
      when Numeric
        value = value.to_r
        raise ArgumentError, ":expires must be a positive value, got #{value}" if value < 0
        value
      else
        raise ArgumentError, ":expires must be Numeric or false, got #{value.inspect}"
      end
    end

    def self.included(base)
      base.supports(:expires) if base.respond_to?(:supports)
    end
  end
end
