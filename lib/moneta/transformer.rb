module Moneta
  # Transforms keys and values (Marshal, YAML, JSON, Base64, MD5, ...).
  # You can bypass the transformer (e.g. serialization) by using the `:raw` option.
  #
  # @example Add `Moneta::Transformer` to proxy stack
  #   Moneta.build do
  #     transformer key: [:marshal, :escape], value: [:marshal]
  #     adapter :File, dir: 'data'
  #   end
  #
  # @example Bypass serialization
  #   store.store('key', 'value', raw: true)
  #   store['key'] # raises an Exception
  #   store.load('key', raw: true) # returns 'value'
  #
  #   store['key'] = 'value'
  #   store.load('key', raw: true) # returns "\x04\bI\"\nvalue\x06:\x06ET"
  #
  # @api public
  class Transformer < Proxy
    config :key do |key:, **_|
      [key].flatten.compact
    end

    config :value do |value:, **_|
      [value].flatten.compact
    end

    def initialize(adapter, options = {})
      super

      if config.key.empty?
        @key_decodable = true
      else
        @key_transforms = load_transforms(config.key, options)
        @key_decodable = @key_transforms.all?(&:decodable?)
        @key_encoder = make_encoder(@key_transforms)
        if @key_decodable
          @key_decoder = make_decoder(@key_transforms)
        end
      end

      unless config.value.empty?
        @value_transforms = load_transforms(config.value, options)
        raise "Not all value transforms are decodable (#{@value_transforms.reject(&:decodable?)})" unless @value_transforms.all?(&:decodable?)
        @value_encoder = make_encoder(@value_transforms)
        @value_decoder = make_decoder(@value_transforms)
      end
    end

    def supports?(feature)
      supported = super
      if supported && feature == :each_key && !@key_decodable
        false
      else
        supported
      end
    end

    def features
      @features ||=
        begin
          features = super
          features -= [:each_key] unless supports?(:each_key)
          features.freeze
        end
    end

    def key?(key, options = {})
      super(encode_key(key), options)
    end

    def each_key
      raise NotImplementedError, "each_key is not supported on this transformer" \
        unless supports? :each_key

      return super unless block_given?

      super do |key|
        next unless encoded_key?(key)
        yield decode_key(key)
      end
    end

    def increment(key, amount = 1, options = {})
      super(encode_key(key), amount, options)
    end

    def create(key, value, options = {})
      super(encode_key(key), encode_value(value, options[:raw]), options)
    end

    def load(key, options = {})
      decode_value(super(encode_key(key), options), options[:raw])
    end

    def store(key, value, options = {})
      super(encode_key(key), encode_value(value, options[:raw]), options)
      value
    end

    def delete(key, options = {})
      decode_value(super(encode_key(key), options), options[:raw])
    end

    def values_at(*keys, raw: false, **options)
      super(*keys.map { |key| encode_key(key) }, **options).map { |value| decode_value(value, raw) }
    end

    def fetch_values(*keys, raw: false, **options)
      if block_given?
        encoded_keys = keys.map { |key| encode_key(key) }
        dictionary = encoded_keys.zip(keys).to_h

        encoded_values =
          super(*encoded_keys, **options) do |encoded_key|
            decoded_value = yield dictionary[encoded_key]
            encode_value(decoded_value, raw) if decoded_value != nil
          end

        encoded_values.map { |value| decode_value(value, raw) }
      else
        values_at(*keys, **options)
      end
    end

    def slice(*keys, raw: false, **options)
      encoded_keys = keys.map { |key| encode_key(key) }
      dictionary = encoded_keys.zip(keys).to_h

      encoded_pairs = super(*encoded_keys, **options)
      encoded_pairs.map do |encoded_key, encoded_value|
        [dictionary[encoded_key], decode_value(encoded_value, raw)]
      end
    end

    def merge!(pairs, options = {})
      encoded_pairs = pairs.map { |key, value| [encode_key(key), encode_value(value, options[:raw])] }
      if block_given?
        key_dictionary = encoded_pairs.map(&:first).zip(pairs.map(&:first)).to_h
        value_dictionary = encoded_pairs.map(&:last).zip(pairs.map(&:last)).to_h

        super(encoded_pairs, options) do |encoded_key, existing_encoded_value, new_encoded_value|
          key = key_dictionary[encoded_key]
          existing_value = decode_value(existing_encoded_value, options[:raw])
          new_value = value_dictionary[new_encoded_value]
          value = yield(key, existing_value, new_value)
          encode_value(value, options[:raw])
        end
      else
        super(encoded_pairs, options)
      end
    end

    private

    # Assume that the key is correctly encoded provided the outer key
    # transform, if any, recognises the key, or if it returns nil (meaning
    # that it doesn't know)
    def encoded_key?(key)
      if @key_transforms
        key_transform = @key_transforms.last
        key_transform.encoded?(key) != false
      else
        true
      end
    end

    def encode_key(key)
      if @key_encoder
        @key_encoder.call(key)
      else
        key
      end
    end

    def decode_key(key)
      raise "keys are not decodable" unless @key_decodable
      if key == nil
        nil
      elsif @key_decoder
        @key_decoder.call(key)
      else
        key
      end
    end

    def encode_value(value, raw)
      if @value_encoder && !raw
        @value_encoder.call(value)
      else
        value
      end
    end

    def decode_value(value, raw)
      if value == nil
        nil
      elsif @value_decoder && !raw
        @value_decoder.call(value)
      else
        value
      end
    end

    def load_transforms(names, options)
      names.map do |transform_name|
        ::Moneta::Transforms.module_for(transform_name).new(**options)
      end
    end

    def make_encoder(transforms)
      lambda do |value|
        transforms.reduce(value) do |value, transform|
          transform.encode(value)
        end
      end
    end

    def make_decoder(transforms)
      reversed = transforms.reverse
      lambda do |value|
        reversed.reduce(value) do |value, transform|
          transform.decode(value)
        end
      end
    end
  end
end
