require 'dm-core'
require 'dm-migrations'

module Moneta
  module Adapters
    # Datamapper backend
    # @api public
    class DataMapper
      include Defaults
      include Config
      include NilValues

      supports :create

      # @api private
      class Store
        include ::DataMapper::Resource
        property :k, String, key: true, length: 255
        property :v, Text, lazy: false
        self.raise_on_save_failure = true
      end

      config :setup, required: true
      config :repository, default: :moneta, coerce: :to_sym
      config :table, default: :moneta, coerce: :to_sym

      # @param [Hash] options
      # @option options [String] :setup Datamapper setup string
      # @option options [String/Symbol] :repository (:moneta) Repository name
      # @option options [String/Symbol] :table (:moneta) Table name
      def initialize(options = {})
        configure(options)
        Store.storage_names[config.repository] = config.table.to_s
        ::DataMapper.setup(config.repository, config.setup)
        context { Store.auto_upgrade! }
      end

      # (see Proxy#key?)
      def key?(key, options = {})
        context { Store.get(key) != nil }
      end

      # (see Proxy#load)
      def load(key, options = {})
        context do
          record = Store.get(key)
          record && record.v
        end
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        context do
          if record = Store.get(key)
            record.update(k: key, v: value)
          else
            Store.create(k: key, v: value)
          end
          value
        end
      rescue
        tries ||= 0
        (tries += 1) < 10 ? retry : raise
      end

      # (see Proxy#create)
      def create(key, value, options = {})
        context do
          Store.create(k: key, v: value)
          true
        end
      rescue
        # FIXME: This catches too many errors
        # it should only catch a not-unique-exception
        false
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        context do
          if record = Store.get(key)
            value = record.v
            record.destroy!
            value
          end
        end
      end

      # (see Proxy#clear)
      def clear(options = {})
        context { Store.all.destroy! }
        self
      end

      private

      def context
        ::DataMapper.repository(config.repository) { yield }
      end
    end
  end
end
