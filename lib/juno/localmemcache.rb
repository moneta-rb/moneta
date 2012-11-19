require 'localmemcache'

module Juno
  class LocalMemCache < Base
    def initialize(options = {})
      raise 'No option :file specified' unless options[:file]
      @store = ::LocalMemCache.new(:filename => options[:file])
    end

    def key?(key, options = {})
      @store.has_key?(key_for(key))
    end

    def delete(key, options = {})
      value = self[key]
      @store.delete(key_for(key))
      value
    end
  end
end
