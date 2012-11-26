module Juno
  # Combines two stores. One is used as cache, the other as backend.
  #
  # Example:
  #
  # ~~~ ruby
  # Juno.build do
  #   use(:Cache) do
  #    backend { adapter :File, :dir => 'data' }
  #    cache { adapter :Memory }
  #   end
  # end
  # ~~~
  class Cache < Base
    class DSL
      def initialize(options, &block)
        @cache, @backend = options[:cache], options[:backend]
        instance_eval(&block)
      end

      def backend(options = {}, &block)
        raise 'Backend already set' if @backend
        @backend = Hash === options ? Juno.build(options, &block) : options
      end

      def cache(options = {}, &block)
        raise 'Cache already set' if @cache
        @cache = Hash === options ? Juno.build(options, &block) : options
      end

      def result
        [@cache, @backend]
      end
    end

    attr_reader :cache, :backend

    def initialize(options = {}, &block)
      @cache, @backend = DSL.new(options, &block).result
    end

    def key?(key, options = {})
      @cache.key?(key, options) || @backend.key?(key, options)
    end

    def load(key, options = {})
      value = @cache.load(key, options)
      unless value
        value = @backend.load(key, options)
        @cache.store(key, value, options) if value
      end
      value
    end

    def store(key, value, options = {})
      @cache.store(key, value, options)
      @backend.store(key, value, options)
    end

    def delete(key, options = {})
      @cache.delete(key, options)
      @backend.delete(key, options)
    end

    def clear(options = {})
      @cache.clear(options)
      @backend.clear(options)
      self
    end

    def close
      @cache.close
      @backend.close
    end
  end
end
