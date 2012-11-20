require 'localmemcache'

module Juno
  module Adapters
    class LocalMemCache < Memory
      def initialize(options = {})
        raise 'No option :file specified' unless options[:file]
        @memory = ::LocalMemCache.new(:filename => options[:file])
      end

      def delete(key, options = {})
        value = load(key, options)
        @memory.delete(key)
        value
      end
    end
  end
end
