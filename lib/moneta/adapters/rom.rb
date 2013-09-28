require 'rom'

module Moneta
  module Adapters
    # Ruby object mapper backend
    # @api public
    class ROM
      include Defaults

      attr_reader :backend

      supports :create, :increment

      class Entry
        attr_accessor :key, :value

        def initialize(attributes)
          @key, @value = attributes.values_at(:key, :value)
        end
      end

      # @param [Hash] options
      # @option options [String/Symbol] :table (:moneta) Table name
      def initialize(options = {})
        t = @table = (options.delete(:table) || :moneta).to_sym
        r = @repository = (options.delete(:repository) || :moneta).to_sym
        @backend = ::ROM::Environment.setup(@repository => 'memory://test')

        @backend.schema do
          base_relation t do
            repository r
            attribute :key,   String
            attribute :value, String
            key :key
          end
        end

        @backend.mapping do
          send(t) do
            map :key, :value
            model Entry
          end
        end
      end

      # (see Proxy#key?)
      def key?(key, options = {})
        @backend[@table].restrict(:key => key).one
        true
      rescue ::ROM::NoTuplesError
        false
      end

      # (see Proxy#load)
      def load(key, options = {})
        @backend[@table].restrict(:key => key).one.value
      rescue ::ROM::NoTuplesError
        nil
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        @backend[@table] << Entry.new(:key => key, :value => value)
        value
      end

      # (see Proxy#create)
      def create(key, value, options = {})
        @backend[@table] << Entry.new(:key => key, :value => value)
        true
      end

      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
        @backend.session do |session|
          entry = session[@table].restrict(:key => key).one
          value = Utils.to_int(entry.value) + amount
          entry.value = value.to_s
          session[@table].save(entry)
        end
      rescue ::ROM::NoTuplesError
        create(key, amount.to_s, options)
        amount
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        @backend.session do |session|
          entry = @backend[@table].restrict(:key => key).one
          @backend[@table].delete(entry)
          session.commit
          entry.value
        end
      rescue ::ROM::NoTuplesError
        nil
      end

      # (see Proxy#clear)
      def clear(options = {})
        @backend[@table].drop(0)
        self
      end
    end
  end
end
