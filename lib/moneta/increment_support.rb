module Moneta
  # @api private
  module IncrementSupport
    # (see Defaults#increment)
    def increment(key, amount = 1, options = {})
      existing = load(key, options)
      value = (existing == nil ? 0 : Integer(existing)) + amount
      store(key, value.to_s, options)
      value
    end

    def self.included(base)
      base.supports(:increment) if base.respond_to?(:supports)
    end
  end
end
