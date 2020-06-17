module Moneta
  # This contains overrides of methods in Defaults where additional nil
  # checks are required, because nil values are possible in the store.
  # @api private
  module NilValues
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

    def slice(*keys, **options)
      keys.zip(values_at(*keys, **options)).reject do |key, value|
        value == nil && !key?(key)
      end
    end

    def merge!(pairs, options = {})
      pairs.each do |key, value|
        if block_given? && key?(key, options)
          existing = load(key, options)
          value = yield(key, existing, value)
        end
        store(key, value, options)
      end
      self
    end
  end
end
