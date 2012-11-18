require 'tokyotyrant'

# FIXME: TokyoTyrant is obsolete, it is replaced by KyotoTycoon
module Juno
  class TokyoTyrant < Base
    def initialize(options = {})
      raise 'No option :host specified' unless options[:host]
      raise 'No option :port specified' unless options[:port]
      @store = ::TokyoTyrant::RDB.new
      unless @store.open(options[:host], options[:port])
        raise @hash.errmsg(@hash.ecode)
      end
    end

    def key?(key, options = {})
      !!self[key]
    end

    def store(key, value, options = {})
      @store.put(key_for(key), serialize(value))
    end

    def delete(key, options = {})
      value = self[key]
      @hash.delete(key_for(key))
      value
    end
  end
end
