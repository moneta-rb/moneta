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

    # Return Moneta store with default option :raw => true
    #
    # @return [OptionMerger]
    # @api public
    def raw
      @raw_store ||=
        begin
          store = with(:raw => true, :only => [:load, :store, :create, :delete])
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
      with(:prefix => prefix, :except => :clear)
    end

    # Return Moneta store with default expiration time
    #
    # @param [Integer] expires Default expiration time
    # @return [OptionMerger]
    # @api public
    def expires(expires)
      with(:expires => expires, :only => [:store, :create, :increment])
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
        @features = (self.features + features).uniq.freeze
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
        default ? default.to_i : nil
      when Numeric
        value = value.to_i
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
