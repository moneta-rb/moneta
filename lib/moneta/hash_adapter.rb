module Moneta
  # @api private
  module HashAdapter
    attr_reader :backend

    # (see Proxy#key?)
    def key?(key, options = {})
      @backend.has_key?(key)
    end

    # (see Proxy#load)
    def load(key, options = {})
      @backend[key]
    end

    # (see Proxy#store)
    def store(key, value, options = {})
      @backend[key] = value
    end

    # (see Proxy#delete)
    def delete(key, options = {})
      @backend.delete(key)
    end

    # (see Proxy#clear)
    def clear(options = {})
      @backend.clear
      self
    end

    # (see Defaults#values_at)
    def values_at(*keys, **options)
      return super unless @backend.respond_to? :values_at
      @backend.values_at(*keys)
    end

    # (see Defaults#fetch_values)
    def fetch_values(*keys, **options, &defaults)
      return super unless @backend.respond_to? :fetch_values
      defaults ||= {} # prevents KeyError
      @backend.fetch_values(*keys, &defaults)
    end

    # (see Defaults#slice)
    def slice(*keys, **options)
      return super unless @backend.respond_to? :slice
      @backend.slice(*keys)
    end

    # (see Defaults#merge!)
    def merge!(pairs, options = {}, &block)
      return super unless method = [:merge!, :update].find do |method|
        @backend.respond_to? method
      end

      hash = Hash === pairs ? pairs : Hash[pairs.to_a]
      case method
      when :merge!
        @backend.merge!(hash, &block)
      when :update
        @backend.update(hash, &block)
      end

      self
    end
  end
end
