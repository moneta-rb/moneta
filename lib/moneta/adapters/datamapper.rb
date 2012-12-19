require 'dm-core'
require 'dm-migrations'

module Moneta
  module Adapters
    # Datamapper backend
    # @api public
    class DataMapper < Base
      class Store
        include ::DataMapper::Resource
        property :k, Text, :key => true
        property :v, Text, :lazy => false
      end

      # Constructor
      #
      # @param [Hash] options
      #
      # Options:
      # * :setup - Datamapper setup string
      # * :repository - Repository name (default :moneta)
      # * :table - Table name (default :moneta)
      def initialize(options = {})
        raise ArgumentError, 'Option :setup is required' unless options[:setup]
        @repository = options.delete(:repository) || :moneta
        Store.storage_names[@repository] = (options.delete(:table) || :moneta).to_s
        ::DataMapper.setup(@repository, options[:setup])
        context { Store.auto_upgrade! }
      end

      def key?(key, options = {})
        context { Store.get(key) != nil }
      end

      def load(key, options = {})
        context do
          record = Store.get(key)
          record ? record.v : nil
        end
      end

      def store(key, value, options = {})
        context do
          record = Store.get(key)
          if record
            record.update(:k => key, :v => value)
          else
            Store.create(:k => key, :v => value)
          end
          value
        end
      end

      def delete(key, options = {})
        context do
          if record = Store.get(key)
            value = record.v
            record.destroy!
            value
          end
        end
      end

      def clear(options = {})
        context { Store.all.destroy! }
        self
      end

      private

      def context
        ::DataMapper.repository(@repository) { yield }
      end
    end
  end
end
