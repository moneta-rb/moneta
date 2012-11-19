module Juno
  class Memory < Base
    def initialize(options = {})
      @store = {}
    end

    def key?(key, options = {})
      @store.has_key?(key_for(key))
    end

    def load(key, options = {})
      deserialize(@store[key_for(key)])
    end

    def store(key, value, options = {})
      @store[key_for(key)] = serialize(value)
      value
    end

    def delete(key, options = {})
      deserialize(@store.delete(key_for(key)))
    end

    def clear(options = {})
      @store.clear
      nil
    end
  end
end
