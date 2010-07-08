module Moneta
  class Memory < Hash
    def initialize(*args)
      @expiration = {}
      super
    end

    def [](key)
      key = Marshal.dump(key)
      super
    end

    def []=(key, value)
      key = Marshal.dump(key)
      super
    end

    def key?(key)
      key = Marshal.dump(key)
      super
    end

    def fetch(key, *args)
      key = Marshal.dump(key)
      super
    end

    def store(key, *args)
      key = Marshal.dump(key)
      super
    end

    def delete(key, *args)
      key = Marshal.dump(key)
      super
    end
  end
end