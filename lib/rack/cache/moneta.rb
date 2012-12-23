require 'moneta'
require 'rack/cache/key'
require 'rack/cache/metastore'
require 'rack/cache/entitystore'

module Rack
  module Cache
    # @api public
    Moneta = {}

    # @api private
    module MonetaResolver
      include Rack::Utils

      def resolve(uri)
        cache = Rack::Cache::Moneta[uri.to_s.sub(%r{^moneta://}, '')] ||=
          begin
            options = parse_query(uri.query)
            options.keys.each do |key|
            options[key.to_sym] =
              case value = options.delete(key)
              when 'true'; true
              when 'false'; false
              else value
              end
          end
            ::Moneta.new(uri.host.to_sym, options)
          end
        new(cache)
      end
    end

    class MetaStore
      # @api public
      class Moneta < MetaStore
        extend MonetaResolver

        def initialize(cache)
          @cache = cache
        end

        def read(key)
          @cache[key] || []
        end

        def write(key, entries)
          @cache[key] = entries
        end

        def purge(key)
          @cache.delete(key)
          nil
        end
      end

      # @api public
      MONETA = Moneta
    end

    class EntityStore
      # @api public
      class Moneta < EntityStore
        extend MonetaResolver

        def initialize(cache)
          @cache = cache
        end

        def open(key)
          data = read(key)
          data && [data]
        end

        def exist?(key)
          @cache.key?(key)
        end

        def read(key)
          @cache[key]
        end

        def write(body, ttl = 0)
          buf = StringIO.new
          key, size = slurp(body) { |part| buf.write(part) }
          @cache.store(key, buf.string, ttl == 0 ? {} : {:expires => ttl})
          [key, size]
        end

        def purge(key)
          @cache.delete(key)
          nil
        end
      end

      # @api public
      MONETA = Moneta
    end
  end
end
