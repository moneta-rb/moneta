require 'rack/utils'
require 'set'

module Juno
  module Adapters
    class Cookie < Base

      attr :unset_cookies

      def initialize(options = {})
        @defaults = {}
        @defaults[:domain] = options[:domain] if options[:domain]
        @defaults[:path]   = options[:path]   if options[:path]
        @defaults[:secure] = options[:secure]
        @defaults[:httponly] = options[:httponly]
        @unset_cookies = Set.new
        @set_cookies = {}
        @cookies = {}
      end

      def key?(key, options = {})
        @cookies.key?(key)
      end

      def load(key, options = {})
        @cookies[key]
      end

      def store(key, value, options = {})
        hash = @defaults.dup
        hash[:value] = value
        hash[:expires] = Time.now.to_i + options[:expires] if options[:expires]
        @cookies[key] = value
        @set_cookies[key] = hash
        @unset_cookies.delete(key)
        return value
      end

      def delete(key, options = {})
        value = @cookies.delete(key)
        @unset_cookies << key
        @set_cookies.delete(key)
        return value
      end

      def clear(options = {})
        @unset_cookies.merge(@cookies.keys)
        @set_cookies.clear
        @cookies.clear
        return self
      end

      def parse(cookie_string)
        @cookies = Rack::Utils.parse_query(cookie_string)
      end

      def unparse(headers)
        @set_cookies.each do |key, value|
          Rack::Utils.set_cookie_header!(headers, key, value)
        end
        @unset_cookies.each do |key|
          Rack::Utils.delete_cookie_header!(headers, key)
        end
      end

    end
  end
end
