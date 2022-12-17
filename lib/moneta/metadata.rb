module Moneta
  # Adds metadata support
  #
  # @api public
  class Metadata < Proxy
    attr_reader :metadata_names

    supports :metadata

    # @param [Moneta store] adapter The underlying store
    # @param [Hash] options
    # @option options [<Symbol>] :metadata A list of metadata field names to
    #   use
    def initialize(adapter, options = {})
      raise 'Store already supports feature :metadata' if adapter.supports?(:metadata)
      @metadata_names = options.delete(:metadata).to_a.freeze
      super
      raise ":value is reserved" if metadata_names.include?(:value)
      @struct = Struct.new(:value, *metadata_names)
    end

    # (see Proxy#create)
    # @option options [{Symbol => String}] :metadata A hash of metadata values to store
    def create(key, value, options = {})
      return super if options.include?(:raw)
      metadata_hash = options[:metadata].to_h
      values = value_with_metadata_hash(value, metadata_hash)
      super(key, values, options)
    end

    # (see Proxy#delete)
    # @option options [Boolean] :return_metadata If true, return a struct including all metadata
    def delete(key, options = {})
      return super if options.include?(:raw)
      return_metadata = options[:return_metadata]
      values = super(key, options)
      return_metadata ? values_to_struct(values) : values_to_value(values)
    end

    # (see Proxy#fetch_values)
    # @param return_metadata [Boolean] :return_metadata If true, each fetched value
    #   is returned as a struct including all metadata
    def fetch_values(*keys, return_metadata: false, raw: false, **options)
      return super if raw
      block = if block_given?
                lambda { |key| [yield(key)] }
              end

      @adapter
        .fetch_values(*keys, **options, &block)
        .map(&method(return_metadata ? :values_to_struct : :values_to_value))
    end

    # (see Proxy#load)
    # @option options [Boolean] :return_metadata If true, return a struct
    #   including all metadata
    def load(key, options = {})
      return super if options.include?(:raw)
      return_metadata = options[:return_metadata]
      values = super(key, options)
      return_metadata ? values_to_struct(values) : values_to_value(values)
    end

    # (see Proxy#merge!)
    # @option options [Boolean] :yield_metadata If true, and a block is
    #   provided, the block will receive structs including all metadata for
    #   each existing value.  This can be used to merge any existing metadata.
    # @option options [{Symbol => String}] :metadata The metadata that should
    #   be associated with all stored values.
    def merge!(pairs, options = {})
      return super if options.include?(:raw)

      block = if block_given?
                return_metadata = options[:yield_metadata]
                lambda do |key, *old_and_new|
                  if return_metadata
                    struct = yield(key, *old_and_new.map(&method(:values_to_struct)))
                    struct.to_a
                  else
                    values = old_and_new.last
                    values[0] = yield(key, *old_and_new.map(&method(:values_to_value)))
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

    # (see Proxy#slice)
    # @param [Boolean] return_metadata if true, each value returned will be a
    #   struct including all metadata
    def slice(*keys, return_metadata: false, raw: false, **options)
      return super if raw
      values_slice = @adapter.slice(*keys, **options)
      if return_metadata
        values_slice.map { |key, values| [key, values_to_struct(values)] }
      else
        values_slice.map { |key, values| [key, values_to_value(values)] }
      end
    end

    # (see Proxy#store)
    # @option options [{Symbol => String}] :metadata A hash of metadata to
    #   store
    # @option options [Boolean] :return_metadata If true, this method will return
    #   a struct including the metadata that was stored
    def store(key, value, options = {})
      return super if options.include?(:raw)
      metadata_hash = options[:metadata].to_h
      return_metadata = options[:return_metadata]
      values = value_with_metadata_hash(value, metadata_hash)
      super(key, values, options)
      return_metadata ? values_to_struct(values) : value
    end

    # (see Proxy#values_at)
    # @param [Boolean] return_metadata If true, each value loaded will be
    #   returned as a struct including any metadata.
    def values_at(*keys, return_metadata: false, raw: false, **options)
      return super if raw
      @adapter
        .values_at(*keys, **options)
        .map(&method(return_metadata ? :values_to_struct : :values_to_value))
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

    def values_to_struct(values)
      if values
        raise 'invalid value' unless Array === values
        @struct.new(*values)
      end
    end

    def values_to_value(values)
      if values
        raise 'invalid value' unless Array === values
        values.first
      end
    end
  end
end
