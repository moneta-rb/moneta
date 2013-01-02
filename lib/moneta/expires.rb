module Moneta
  # Adds expiration support to the underlying store
  #
  # `#store`, `#load` and `#key?` support the `:expires` option to set/update
  # the expiration time.
  #
  # @api public
  class Expires < Proxy
    # @param [Moneta store] adapter The underlying store
    # @param [Hash] options
    # @option options [String] :expires Default expiration time
    def initialize(adapter, options = {})
      super
      @expires = options[:expires]
    end

    # (see Proxy#key?)
    def key?(key, options = {})
      # Transformer might raise exception
      load_entry(key, options) != nil
    rescue Exception
      options.include?(:expires) && (options = options.dup; options.delete(:expires))
      super(key, options)
    end

    # (see Proxy#load)
    def load(key, options = {})
      return super if options.include?(:raw)
      value, expires = load_entry(key, options)
      value
    end

    # (see Proxy#store)
    def store(key, value, options = {})
      return super if options.include?(:raw)
      expires = options.include?(:expires) && (options = options.dup; options.delete(:expires))
      if expires ||= @expires
        super(key, [value, Time.now.to_i + expires], options)
      elsif Array === value || value == nil
        super(key, [value], options)
      else
        super(key, value, options)
      end
      value
    end

    # (see Proxy#delete)
    def delete(key, options = {})
      return super if options.include?(:raw)
      value, expires = super
      value if !expires || Time.now.to_i <= expires
    end

    private

    def load_entry(key, options)
      new_expires = options.include?(:expires) && (options = options.dup; options.delete(:expires))
      entry = @adapter.load(key, options)
      if entry != nil
        value, expires = entry
        if expires && Time.now.to_i > expires
          delete(key)
          nil
        elsif new_expires
          @adapter.store(key, [value, Time.now.to_i + new_expires], options)
          entry
        else
          entry
        end
      end
    end
  end
end
