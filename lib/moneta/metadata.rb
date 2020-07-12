module Moneta
  # Adds metadata support
  #
  # @api public
  class Metadata < Proxy
    attr_reader :metadata_names

    # FIXME
    def initialize(adapter, options = {})
      raise 'Store already supports feature :metadata' if adapter.supports?(:metadata)
      @metadata_names = options.delete(:names).to_a.freeze
      super
      raise ":value is reserved" if metadata_names.include?(:value)
      @struct = Struct.new(:value, *metadata_names)
    end

    # (see Defaults#create)
    def create(key, value, options = {})
      return super if options.include?(:raw)
      metadata_hash = options[:metadata].to_h
      values = value_with_metadata_hash(value, metadata_hash)
      super(key, values, options)
    end

    # (see Defaults#delete)
    def delete(key, options = {})
      return super if options.include?(:raw)
      load_metadata = options[:load_metadata]
      values = super(key, options)
      if values != nil
        load_metadata ? @struct.new(*values) : values.first
      end
    end

    # (see Defaults#fetch_values)
    def fetch_values(*keys, load_metadata: false, raw: false, **options)
      return super if raw
      block = if block_given?
                lambda { |key| [yield(key)] }
              end

      values_array = @adapter.fetch_values(*keys, **options, &block)
      if load_metadata
        values_array.map { |values| values && @struct.new(*values) }
      else
        values_array.map { |values| values && values.first }
      end
    end

    # (see Defaults#load)
    def load(key, options = {})
      return super if options.include?(:raw)
      load_metadata = options[:load_metadata]
      values = super(key, options)
      unless values == nil
        raise 'invalid value' unless Array === values
        load_metadata ? @struct.new(*values) : values.first
      end
    end

    # (see Defaults#merge!)
    def merge!(pairs, options = {})
      return super if options.include?(:raw)

      block = if block_given?
                load_metadata = options[:load_metadata]
                lambda do |key, old_values, values|
                  if load_metadata
                    struct = yield(key, @struct.new(*old_values), @struct.new(*values))
                    struct.to_a
                  else
                    values[0] = yield(key, old_values.first, values.first)
                    values
                  end
                end
              end

      metadata_values = metadata_values_from_hash(options[:metadata].to_h)
      pairs_with_metadata = pairs.map do |key, value|
        [key, value_with_metadata_values(value, metadata_values)]
      end

      @adapter.merge!(pairs_with_metadata, options, &block)
      self
    end

    # (see Defaults#slice)
    def slice(*keys, load_metadata: false, raw: false, **options)
      return super if raw
      values_slice = @adapter.slice(*keys, **options)
      if load_metadata
        values_slice.map { |key, values| [key, @struct.new(*values)] }
      else
        values_slice.map { |key, values| [key, values.first] }
      end
    end

    # (see Defaults#store)
    def store(key, value, options = {})
      return super if options.include?(:raw)
      metadata_hash = options[:metadata].to_h
      load_metadata = options[:load_metadata]
      values = value_with_metadata_hash(value, metadata_hash)
      super(key, values, options)
      load_metadata ? @struct.new(*values) : value
    end

    # (see Defaults#values_at)
    def values_at(*keys, load_metadata: false, raw: false, **options)
      return super if raw
      values_array = @adapter.values_at(*keys, **options)
      if load_metadata
        values_array.map { |values| values && @struct.new(*values) }
      else
        values_array.map { |values| values && values.first }
      end
    end

    private

    def metadata_values_from_hash(metadata_hash)
      metadata_hash.values_at(*metadata_names)
    end

    def value_with_metadata_hash(value, metadata_hash)
      value_with_metadata_values(value, metadata_values_from_hash(metadata_hash))
    end

    def value_with_metadata_values(value, metadata_values)
      metadata_values.dup.unshift(value)
    end

    class << self
      def included(base)
        base.supports(:metadata) if base.respond_to?(:supports)
      end
    end
  end
end
