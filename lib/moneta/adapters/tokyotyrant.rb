require 'tokyotyrant'

module Moneta
  module Adapters
    # TokyoTyrant backend
    # @api public
    class TokyoTyrant < Memory
      # @param [Hash] options
      # @option options [String] :host ('127.0.0.1') Server host name
      # @option options [Integer] :port (1978) Server port
      def initialize(options = {})
        options[:host] ||= '127.0.0.1'
        options[:port] ||=  1978
        @hash = ::TokyoTyrant::RDB.new
        @hash.open(options[:host], options[:port]) or raise @hash.errmsg(@hash.ecode)
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        value = load(key, options)
        if value
          @hash.delete(key)
          value
        end
      end

      # (see Proxy#create)
      def create(key, value, options = {})
        @hash.putkeep(key, value)
      end

      # (see Proxy#close)
      def close
        @hash.close
        nil
      end
    end
  end
end
