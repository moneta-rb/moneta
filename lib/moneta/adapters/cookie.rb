module Moneta
  module Adapters
    class Cookie < Memory
      attr_reader :cookies

      def initialize(options = {})
        super
        @options, @cookies = options, {}
      end

      def store(key, value, options = {})
        cookie = @options.merge(options)
        cookie[:value] = value
        cookie[:expires] += Time.now.to_i if cookie[:expires]
        @cookies[key] = cookie
        super
      end

      def delete(key, options = {})
        @cookies[key] = nil
        super
      end

      def clear(options = {})
        @memory.each_key { |key| @cookies[key] = nil }
        super
        self
      end

      def reset(cookies)
        @cookies, @memory = {}, cookies
      end
    end
  end
end
