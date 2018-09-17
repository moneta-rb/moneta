module Moneta
  # Wraps the calls to the adapter
  # @api public
  class Wrapper < Proxy
    # (see Proxy#key?)
    def key?(key, options = {})
      wrap(:key?, key, options) { super }
    end

    # (see Proxy#load)
    def load(key, options = {})
      wrap(:load, key, options) { super }
    end

    # (see Proxy#store)
    def store(key, value, options = {})
      wrap(:store, key, value, options) { super }
    end

    # (see Proxy#delete)
    def delete(key, options = {})
      wrap(:delete, key, options) { super }
    end

    # (see Proxy#increment)
    def increment(key, amount = 1, options = {})
      wrap(:increment, key, amount, options) { super }
    end

    # (see Proxy#create)
    def create(key, value, options = {})
      wrap(:create, key, value, options) { super }
    end

    # (see Proxy#clear)
    def clear(options = {})
      wrap(:clear, options) { super }
    end

    # (see Proxy#close)
    def close
      wrap(:close) { super }
    end

    # (see Proxy#features)
    def features
      wrap(:features) { super }
    end

    # (see Proxy#each_key)
    def each_key(&block)
      wrap(:each_key) { super }
    end

    # (see Proxy#values_at)
    def values_at(*keys, **options)
      wrap(:values_at, keys, options) { super }
    end

    # (see Proxy#fetch_values)
    def fetch_values(*keys, **options, &defaults)
      wrap(:fetch_values, keys, options, defaults) { super }
    end

    # (see Proxy#slice)
    def slice(*keys, **options)
      wrap(:slice, keys, options) { super }
    end

    # (see Proxy#merge!)
    def merge!(pairs, options = {})
      wrap(:merge!, pairs, options) { super }
    end
  end
end
