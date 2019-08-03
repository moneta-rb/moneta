module Moneta
  # Provides a fallback to a second store when an exception is raised
  #
  # @example Basic usage - catches any {IOError} and falls back to {Moneta::Adapters:Null}
  #   Moneta.build do
  #     use :Fallback
  #     adapter :Client
  #   end
  #
  # @example Specifying an exception to rescue
  #   Moneta.build do
  #     use :Fallback, rescue: Redis::CannotConnectError
  #     adapter :Redis
  #   end
  #
  # @example Specifying a different fallback
  #   Moneta.build do
  #     use :Fallback do
  #       # This is a new builder context
  #       adapter :Memory
  #     end
  #     adapter :File, dir: 'cache'
  #   end
  #
  # @api public
  class Fallback < Wrapper
    # @param [Moneta store] adapter The underlying store
    # @param [Hash] options
    # @option options [Moneta store] :fallback (:Null store) The store to fall
    #   back on
    # @option options [Class|Array<Class>] :rescue ([IOError]) The list
    #   of exceptions that should be rescued
    # @yieldreturn [Moneta store] Moneta store built using the builder API
    def initialize(adapter, options = {}, &block)
      super

      @fallback =
        if block_given?
          ::Moneta.build(&block)
        elsif options.key?(:fallback)
          options.delete(:fallback)
        else
          ::Moneta::Adapters::Null.new
        end

      @rescue =
        case options[:rescue]
        when nil
          [::IOError]
        when Array
          options[:rescue]
        else
          [options[:rescue]]
        end
    end

    protected

    def wrap(name, *args, &block)
      yield
    rescue => e
      raise unless @rescue.any? { |rescuable| rescuable === e }
      fallback(name, *args, &block)
    end

    def fallback(name, *args, &block)
      result =
        case name
        when :values_at, :fetch_values, :slice
          keys, options = args
          @fallback.public_send(name, *keys, **options, &block)
        else
          @fallback.public_send(name, *args, &block)
        end

      # Don't expose the fallback class to the caller
      if result == @fallback
        self
      else
        result
      end
    end
  end
end
