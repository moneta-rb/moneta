require 'dm-core'
require 'dm-migrations'

module Juno
  module Adapters
    # Datamapper backend
    # @api public
    class DataMapper < Base
      class Store
        include ::DataMapper::Resource
        property :k, String, :key => true
        property :v, Object, :lazy => false
      end

      # Constructor
      #
      # @param [Hash] options
      #
      # Options:
      # * :setup - Datamapper setup string
      # * :repository - Repository name (default :juno)
      # * :table - Table name (default :juno)
      def initialize(options = {})
        raise 'No option :setup specified' unless options[:setup]
        @repository = options.delete(:repository) || :juno
        Store.storage_names[@repository] = (options.delete(:table) || :juno).to_s
        ::DataMapper.setup(@repository, options[:setup])
        context { Store.auto_upgrade! }
      end

      def key?(key, options = {})
        context { !!Store.get(key) }
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
