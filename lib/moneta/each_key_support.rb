module Moneta
  # This provides an each_key implementation that works in most cases.
  # @api private
  module EachKeySupport
    def each_key
      return enum_for(:each_key) unless block_given?

      if @backend.respond_to?(:each_key)
        @backend.each_key { |key| yield key }
      elsif @backend.respond_to?(:keys)
        if keys = @backend.keys
          keys.each { |key| yield key }
        end
      elsif @backend.respond_to?(:each)
        @backend.each { |key, _| yield key }
      else
        raise ::NotImplementedError, "No enumerable found on backend"
      end

      self
    end

    def self.included(base)
      base.supports(:each_key) if base.respond_to?(:supports)
    end
  end
end
