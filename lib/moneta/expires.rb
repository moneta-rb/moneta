require 'set'

module Moneta
  # Adds expiration support to the underlying store
  #
  # `#store`, `#load` and `#key?` support the `:expires` option to set/update
  # the expiration time.
  #
  # @api public
  class Expires < Proxy
    include ExpiresSupport

    # @param [Moneta store] adapter The underlying store
    # @param [Hash] options
    # @option options [String] :expires Default expiration time
    def initialize(adapter, options = {})
      raise 'Store already supports feature :expires' if adapter.supports?(:expires)
      if !adapter.supports?(:metadata) || !adapter.metadata_names.include?(:expires)
        adapter = Metadata.new(adapter, options.merge(names: [:expires]))
      end
      self.default_expires = options[:expires]
      super
    end

    # (see Proxy#key?)
    def key?(key, options = {})
      return super if options.include?(:raw)
      begin
        nil != load_or_expire(key: key, load_metadata: true, options: Utils.without(options, :load_metadata))
      rescue
        # Fallback for if the key is present but can't be loaded
        super(key, Utils.without(options, :expires))
      end
    end

    # (see Proxy#load)
    def load(key, options = {})
      return super if options.include?(:raw)
      load_metadata = options[:load_metadata]
      load_or_expire(key: key, load_metadata: load_metadata, options: options)
    end

    # (see Proxy#store)
    def store(key, value, options = {})
      return super if options.include?(:raw)
      expires = expires_at(options)
      options_with_metadata = update_options_with_metadata(expires: expires, options: options)
      super(key, value, options_with_metadata)
    end

    # (see Proxy#delete)
    def delete(key, options = {})
      return super if options.include?(:raw)
      load_metadata = options[:load_metadata]
      if struct = load_or_expire(key: key, load_metadata: true, options: options, allow_expiry_update: false)
        super(key, options)
        load_metadata ? struct : struct.value
      end
    end

    # (see Proxy#store)
    def create(key, value, options = {})
      return super if options.include?(:raw)
      expires = expires_at(options)
      options_with_metadata = update_options_with_metadata(expires: expires, options: options)
      @adapter.create(key, value, options_with_metadata)
    end

    # (see Defaults#values_at)
    def values_at(*keys, **options)
      return super if options.include?(:raw)
      load_metadata = options[:load_metadata]
      expires = expires_at(options, nil)
      options = Utils.without(options, :expires).merge(load_metadata: true)

      structs = @adapter.values_at(*keys, **options)
      keys.zip(structs).map do |key, struct|
        next if struct == nil || delete_if_expired(key: key, struct: struct)
        if expires != nil
          options_with_metadata = update_options_with_metadata(expires: expires, options: options, metadata: struct.to_h)
          struct = @adapter.store(key, struct.value, options_with_metadata)
        end
        load_metadata ? struct : struct.value
      end
    end

    # (see Defaults#fetch_values)
    def fetch_values(*keys, **options)
      return super if options.include?(:raw)
      load_metadata = options[:load_metadata]
      expires = expires_at(options, nil)
      options = Utils.without(options, :expires).merge(load_metadata: true)

      substituted = Set.new
      block = if block_given?
                lambda do |key|
                  substituted << key
                  yield key
                end
              end

      structs = @adapter.fetch_values(*keys, **options, &block)
      keys.zip(structs).map do |key, struct|
        unless substituted.include? key
          next if struct == nil
          if delete_if_expired(key: key, struct: struct)
            if block_given?
              struct.value = yield key
            else
              next
            end
          elsif expires != nil
            options_with_metadata = update_options_with_metadata(expires: expires, options: options, metadata: struct.to_h)
            struct = @adapter.store(key, struct.value, options_with_metadata)
          end
        end
        load_metadata ? struct : struct.value
      end
    end

    # (see Defaults#slice)
    def slice(*keys, **options)
      return super if options.include?(:raw)
      load_metadata = options[:load_metadata]
      expires = expires_at(options, nil)
      options = Utils.without(options, :expires).merge(load_metadata: true)

      @adapter.slice(*keys, **options).each_with_object([]) do |(key, struct), slice|
        next if delete_if_expired(key: key, struct: struct)
        if expires != nil
          options_with_metadata = update_options_with_metadata(expires: expires, options: options, metadata: struct.to_h)
          struct = @adapter.store(key, struct.value, options_with_metadata)
        end
        slice.push [key, load_metadata ? struct : struct.value]
      end
    end

    # (see Defaults#merge!)
    def merge!(pairs, options = {})
      load_metadata = options[:load_metadata]
      expires = expires_at(options)
      options = Utils.without(options, :expires).merge(load_metadata: true)
      options_with_metadata = update_options_with_metadata(expires: expires, options: options)

      block = if block_given?
                lambda do |key, old_struct, struct|
                  next struct if delete_if_expired(key: key, struct: old_struct)

                  if load_metadata
                    yield key, old_struct, struct
                  else
                    struct.value = yield key, old_struct.value, struct.value
                    struct
                  end
                end
              end

      @adapter.merge!(pairs, options_with_metadata, &block)
      self
    end

    private

    def load_or_expire(key:, options:, load_metadata: false, allow_expiry_update: true)
      options = options.merge(load_metadata: true)
      struct = @adapter.load(key, options)
      return if struct == nil
      struct =
        if delete_if_expired(key: key, struct: struct)
          nil
        elsif allow_expiry_update && (expires = expires_at(options, nil)) != nil
          options_with_metadata = update_options_with_metadata(expires: expires, options: options, metadata: struct.to_h)
          @adapter.store(key, struct.value, options_with_metadata)
        else
          struct
        end

      struct && (load_metadata ? struct : struct.value)
    end

    def delete_if_expired(key:, struct:)
      if struct.expires && Time.now > Time.at(struct.expires)
        @adapter.delete key
        true
      else
        false
      end
    end

    def update_options_with_metadata(expires:, options:, metadata: nil)
      metadata ||= options[:metadata].to_h
      Utils.without(options, :expires, :metadata).merge \
        metadata: metadata.merge(expires: expires ? expires.to_r : nil)
    end
  end
end
