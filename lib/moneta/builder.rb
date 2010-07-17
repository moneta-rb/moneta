module Moneta
  module Middleware
    def self.included(klass)
      class << klass
        alias build new
      end
    end

    def build(adapter)
      @adapter = adapter
    end

    def [](key)
      @adapter[key]
    end

    def []=(key, value)
      @adapter[key] = value
    end

    def fetch(*args, &block)
      @adapter.fetch(*args, &block)
    end

    def delete(key, *args)
      @adapter.delete(key, *args)
    end

    def store(key, value, *args)
      @adapter.store(key, value, *args)
    end

    def update_key(key, options)
      @adapter.update_key(key, options)
    end

    def key?(key, *args)
      @adapter.key?(key, *args)
    end

    def clear(*args)
      @adapter.clear(*args)
    end

    def close
      @adapter.close
    end
  end

  class Builder
    include Middleware

    def initialize(&block)
      @middlewares = []
      @adapter     = nil
      instance_eval(&block)
    end

    def use(middleware, *args, &block)
      @middlewares << middleware.build(*args, &block)
    end

    def run(adapter, *args, &block)
      @adapter = adapter.new(*args, &block)

      @middlewares.reverse.each do |middleware|
        @adapter = middleware.build(@adapter)
      end
    end

  end
end
