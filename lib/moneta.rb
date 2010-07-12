require "moneta/builder"

module Moneta
  module Defaults
    def fetch(key, value = nil)
      self[key_for(key)] || begin
        value ||= block_given? ? yield(key) : default
        self[key_for(key)] || value
      end
    end

    def store(key, value, options = {})
      self[key_for(key)] = value
    end

  private
    def key_for(key)
      key.is_a?(String) ? key : Marshal.dump(key)
    end
  end
end
