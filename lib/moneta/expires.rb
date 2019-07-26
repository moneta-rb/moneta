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
      super
      self.default_expires = options[:expires]
    end

    # (see Proxy#key?)
    def key?(key, options = {})
      # Transformer might raise exception
      load_entry(key, options) != nil
    rescue
      super(key, Utils.without(options, :expires))
    end

    # (see Proxy#load)
    def load(key, options = {})
      return super if options.include?(:raw)
      value, = load_entry(key, options)
      value
    end

    # (see Proxy#store)
    def store(key, value, options = {})
      return super if options.include?(:raw)
      expires = expires_at(options)
      super(key, new_entry(value, expires), Utils.without(options, :expires))
      value
    end

    # (see Proxy#delete)
    def delete(key, options = {})
      return super if options.include?(:raw)
      value, expires = super
      value if !expires || Time.now <= Time.at(expires)
    end

    # (see Proxy#store)
    def create(key, value, options = {})
      return super if options.include?(:raw)
      expires = expires_at(options)
      @adapter.create(key, new_entry(value, expires), Utils.without(options, :expires))
    end

    # (see Defaults#values_at)
    def values_at(*keys, **options)
      return super if options.include?(:raw)
      new_expires = expires_at(options, nil)
      options = Utils.without(options, :expires)
      with_updates(options) do |updates|
        keys.zip(@adapter.values_at(*keys, **options)).map do |key, entry|
          entry = invalidate_entry(key, entry, new_expires) do |new_entry|
            updates[key] = new_entry
          end
          next if entry == nil
          value, = entry
          value
        end
      end
    end

    # (see Defaults#fetch_values)
    def fetch_values(*keys, **options)
      return super if options.include?(:raw)
      new_expires = expires_at(options, nil)
      options = Utils.without(options, :expires)
      substituted = {}
      block = if block_given?
                lambda do |key|
                  substituted[key] = true
                  yield key
                end
              end

      with_updates(options) do |updates|
        keys.zip(@adapter.fetch_values(*keys, **options, &block)).map do |key, entry|
          next entry if substituted[key]
          entry = invalidate_entry(key, entry, new_expires) do |new_entry|
            updates[key] = new_entry
          end
          if entry == nil
            value = if block_given?
                      yield key
                    end
          else
            value, = entry
          end
          value
        end
      end
    end

    # (see Defaults#slice)
    def slice(*keys, **options)
      return super if options.include?(:raw)
      new_expires = expires_at(options, nil)
      options = Utils.without(options, :expires)

      with_updates(options) do |updates|
        @adapter.slice(*keys, **options).map do |key, entry|
          entry = invalidate_entry(key, entry, new_expires) do |new_entry|
            updates[key] = new_entry
          end
          next if entry == nil
          value, = entry
          [key, value]
        end.reject(&:nil?)
      end
    end

    # (see Defaults#merge!)
    def merge!(pairs, options = {})
      expires = expires_at(options)
      options = Utils.without(options, :expires)

      block = if block_given?
                lambda do |key, old_entry, entry|
                  old_entry = invalidate_entry(key, old_entry)
                  if old_entry == nil
                    entry # behave as if no replace is happening
                  else
                    old_value, = old_entry
                    new_value, = entry
                    new_entry(yield(key, old_value, new_value), expires)
                  end
                end
              end

      entry_pairs = pairs.map do |key, value|
        [key, new_entry(value, expires)]
      end
      @adapter.merge!(entry_pairs, options, &block)
      self
    end

    private

    def load_entry(key, options)
      new_expires = expires_at(options, nil)
      options = Utils.without(options, :expires)
      entry = @adapter.load(key, options)
      invalidate_entry(key, entry, new_expires) do |new_entry|
        @adapter.store(key, new_entry, options)
      end
    end

    def invalidate_entry(key, entry, new_expires = nil)
      if entry != nil
        value, expires = entry
        if expires && Time.now > Time.at(expires)
          delete(key)
          entry = nil
        elsif new_expires != nil
          yield new_entry(value, new_expires) if block_given?
        end
      end
      entry
    end

    def new_entry(value, expires)
      if expires
        [value, expires.to_r]
      elsif Array === value || value == nil
        [value]
      else
        value
      end
    end

    def with_updates(options)
      updates = {}
      yield(updates).tap do
        @adapter.merge!(updates, options) unless updates.empty?
      end
    end
  end
end
