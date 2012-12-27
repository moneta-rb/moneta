module Moneta
  module Adapters
    # Cookie backend used by `Rack::MonetaCookies`
    # @api public
    class Cookie < Memory
      attr_reader :cookies

      def initialize(options = {})
        super
        @options, @cookies = options, {}
      end

      # @see Proxy#store
      def store(key, value, options = {})
        cookie = @options.merge(options)
        cookie[:value] = value
        cookie[:expires] += Time.now.to_i if cookie[:expires]
        @cookies[key] = cookie
        super
      end

      # @see Proxy#delete
      def delete(key, options = {})
        @cookies[key] = nil
        super
      end

      # @see Proxy#clear
      def clear(options = {})
        @hash.each_key { |key| @cookies[key] = nil }
        super
        self
      end

      def reset(cookies)
        @cookies, @hash = {}, cookies
      end
    end
  end
end
