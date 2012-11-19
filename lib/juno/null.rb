module Juno
  class Null < Base
    def key?(key, options = {})
      false
    end

    def [](key)
      nil
    end

    def store(key, value, options = {})
      value
    end

    def delete(key, options = {})
      nil
    end

    def clear(options = {})
      nil
    end
  end
end
