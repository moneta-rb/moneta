module Moneta
  module Defaults
    def fetch(key, value = nil)
      key = Marshal.dump(key)
      value ||= block_given? ? yield(key) : default
      self[key] || value
    end

    def store(key, value, options = {})
      key = Marshal.dump(key)
      self[key] = value
    end
  end
end
