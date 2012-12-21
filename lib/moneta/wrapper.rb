module Moneta
  # Wraps the calls to the adapter
  # @api public
  class Wrapper < Proxy
    def key?(key, options = {})
      wrap(:key?, key, options) { super }
    end

    def load(key, options = {})
      wrap(:load, key, options) { super }
    end

    def store(key, value, options = {})
      wrap(:store, key, value, options) { super }
    end

    def delete(key, options = {})
      wrap(:delete, key, options) { super }
    end

    def clear(options = {})
      wrap(:clear, options) { super }
    end

    def close
      wrap(:close) { super }
    end
  end
end
