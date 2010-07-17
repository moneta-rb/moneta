require "moneta/builder"

module Moneta
  module Defaults
    def fetch(key, value = nil, *)
      self[key] || begin
        value ||= block_given? ? yield(key) : default
        self[key] || value
      end
    end

    def []=(key, value)
      store(key, value)
    end

  private
    def key_for(key)
      key.is_a?(String) ? key : Marshal.dump(key)
    end

    def serialize(value)
      Marshal.dump(value)
    end

    def deserialize(value)
      value && Marshal.load(value)
    end
  end
end
