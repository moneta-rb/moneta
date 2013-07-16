require 'net/sftp'

module Moneta
  module Adapters
    # SFTP backend
    # @api public
    class SFTP
      include Defaults

      attr_reader :backend

      # @param [Hash] options
      # @option options [String] :host Server host
      # @option options [String] :user Username used to authenticate
      # @option options [String] :dir Directory where files will be stored
      def initialize(options = {})
        raise ArgumentError, 'Option :host is required' unless host = options.delete(:host)
        raise ArgumentError, 'Option :user is required' unless user = options.delete(:user)
        raise ArgumentError, 'Option :dir is required' unless @dir = options.delete(:dir)
        @backend = ::Net::SFTP.start(host, user, options)
      end

      # (see Proxy#key?)
      def key?(key, options = {})
        @backend.stat(store_path(key))
      end

      # (see Proxy#load)
      def load(key, options = {})
        @backend.download!(store_path(key))
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        # todo mkdir
        @backend.file.open(store_path(key), 'w') do |f|
          f.write(value)
        end
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        value = load(key, options)
        @backend.remove!(store_path(key))
        value
      end

      # (see Proxy#clear)
      def clear(options = {})
        @backend.dir.foreach(@dir) do |key|
          # todo recursive delete
        end
      end

      # (see Proxy#close)
      def close
        @backend.close
        @backend = nil
      end

      protected

      def store_path(key)
        ::File.join(@dir, key)
      end
    end
  end
end
