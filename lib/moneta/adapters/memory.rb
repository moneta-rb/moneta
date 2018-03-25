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

      def each_key(&block)
        return enum_for(:each_key) unless block_given?

        if @backend.respond_to?(:each_key)
          @backend.each_key(&block)
        elsif @backend.respond_to?(:keys)
          @backend.keys&.each(&block)
        elsif @backend.respond_to?(:each)
          @backend.each { |k| yield(k) }
        else
          raise ::NotImplementedError, "No enumerator found on backend"
        end

        self
      end
    end
  end
end
