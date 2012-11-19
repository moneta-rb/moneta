module Juno
  class Stack < Base
    def initialize(options = {})
      raise 'No option :stores specified' unless @stores = options[:stores]
    end

    def key?(key, options = {})
      @stores.any? {|s| s.key?(key) }
    end

    def [](key)
      @stores.each do |s|
        value = s[key]
        return value if value
      end
      nil
    end

    def store(key, value, options = {})
      @stores.each {|s| s.store(key, value, options) }
      value
    end

    def delete(key, options = {})
      @stores.inject(nil) do |value, s|
        v = s.delete(key, options)
        value || v
      end
    end

    def clear(options = {})
      @stores.each {|s| s.clear }
      nil
    end

    def close
      @stores.each {|s| s.close }
      nil
    end
  end
end
