module Moneta
  # Adapter base class
  # @api public
  class Adapter
    include Defaults
    include Config

    attr_reader :backend

    class << self
      # Define a block used to build this adapter's backend.  The block will
      # receive as keyword arguments any options passed to the adapter during
      # initialization that are not config settings.
      #
      # If the adapter is initialized with a `:backend` option, this will be used
      # instead, and the block won't be called.
      #
      # @param [Boolean] required
      # @yield [**options] options passed to the adapter's initialize method
      # @yieldreturn [Object] The backend to use
      def backend(required: true, &block)
        raise "backend block already set" if class_variables(false).include?(:@@backend_block)
        class_variable_set(:@@backend_block, block)
        class_variable_set(:@@backend_required, true) if required
      end

      def backend_block
        class_variable_get(:@@backend_block) if class_variable_defined?(:@@backend_block)
      end

      def backend_required?
        class_variable_defined?(:@@backend_required)
      end
    end

    # @param [Hash] options
    def initialize(options = {})
      set_backend(**configure(**options))
    end

    private

    def set_backend(backend: nil, **options)
      @backend = backend ||
        if backend_block = self.class.backend_block
          instance_exec(**options, &backend_block)
        end

      raise ArgumentError, 'backend needs to be set - refer to adapter documentation' if !@backend && self.class.backend_required?
    end
  end
end
