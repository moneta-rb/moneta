module Moneta
  module Adapters
    # Memory backend using a hash to store the entries
    # @api public
    class Memory
      include Defaults
      include HashAdapter
      include IncrementSupport
      include CreateSupport

      supports :each_key

      # @param [Hash] options Options hash
      # @option options [Hash] :backend Use existing backend instance
      def initialize(options = {})
        @backend = options[:backend] || {}
      end

      # (see Defaults#each_key)
      def each_key
        if @backend.respond_to?(:each_key)
          return @backend.enum_for(:each_key) unless block_given?
          @backend.each_key { |k| yield(k) }
          return self
        elsif @backend.respond_to?(:keys)
          return @backend.keys.enum_for unless block_given?
          @backend.keys&.each { |k| yield(k) }
          return self
        elsif @backend.respond_to?(:each)
          if block_given?
            @backend.each { |k, v| yield(k) }
            return self
          else
            Enumerator.new do |y|
              @backend.each { |k, v| y << k }
            end
          end
        else
          raise ::NotImplementedError, "No enumerator found on backend"
        end
      end
    end
  end
end
