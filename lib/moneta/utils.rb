module Moneta
  # @api private
  module Utils
    extend self

    def without(hash, *keys)
      return hash if hash.empty?
      if keys.any? {|k| hash.include?(k) }
        hash = hash.dup
        keys.each {|k| hash.delete(k) }
      end
      hash
    end

    def only(hash, *keys)
      return hash if hash.empty?
      ret = {}
      keys.each {|k| ret[k] = hash[k] }
      ret
    end

    def to_int(value)
      intvalue = value.to_i
      raise "#{value.inspect} is not an integer value" unless value == nil || intvalue.to_s == value.to_s
      intvalue
    end
  end
end
