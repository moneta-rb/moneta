require 'kyotocabinet'

module Moneta
  module Adapters
    # KyotoCabinet backend
    # @api public
    class KyotoCabinet
      include Defaults
      include HashAdapter

      supports :each_key, :increment, :create

      # @param [Hash] options
      # @option options [String] :file Database file
      # @option options [::KyotoCabinet::DB] :backend Use existing backend instance
      def initialize(options = {})
        if options[:backend]
          @backend = options[:backend]
        else
          raise ArgumentError, 'Option :file is required' unless options[:file]
          @backend = ::KyotoCabinet::DB.new
          raise @backend.error.to_s unless @backend.open(options[:file],
                                                         ::KyotoCabinet::DB::OWRITER | ::KyotoCabinet::DB::OCREATE)
        end
      end

      # (see Proxy#key?)
      def key?(key, options = {})
        @backend.check(key) >= 0
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        @backend.seize(key)
      end

      # (see Proxy#create)
      def create(key, value, options = {})
        @backend.add(key, value)
      end

      # (see Proxy#close)
      def close
        @backend.close
        nil
      end

      # (see Proxy#each_key)
      def each_key
        return enum_for(:each_key) { @backend.count } unless block_given?
        @backend.each_key{ |arr| yield arr[0] }
        self
      end

      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
        ret = nil
        success = @backend.accept(key) do |key, value|
          if value
            ret = Integer(value) + amount
          else
            ret = amount
          end
          ret.to_s
        end

        raise @backend.error unless success
        ret
      end

      # (see Proxy#slice)
      def slice(*keys, atomic: true, **options)
        @backend.get_bulk(keys, atomic)
      end

      # (see Proxy#values_at)
      def values_at(*keys, **options)
        hash = slice(*keys, **options)
        keys.map { |key| hash[key] }
      end

      # (see Proxy#merge!)
      def merge!(pairs, options = {})
        hard = options.key?(:hard) ? options[:hard] : false
        atomic = options.key?(:atomic) ? options[:atomic] : true

        success =
          if block_given?
            @backend.transaction(hard) do
              existing = slice(*pairs.map { |k, _| k }, **options)
              pairs = pairs.map do |key, new_value|
                if existing.key?(key)
                  [key, yield(key, existing[key], new_value)]
                else
                  [key, new_value]
                end
              end
              @backend.set_bulk(pairs.to_h, atomic) >= 0
            end
          else
            @backend.set_bulk(pairs.to_h, atomic) >= 0
          end

        raise @backend.error unless success
        self
      end
    end
  end
end
