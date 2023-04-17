require "forwardable"

module Moneta
  # Handles encoding/decoding of arbitrary objects into something that can be stored in a backend.  Most transforms
  # encode to string.
  #
  # @abstract Subclasses should implement {#encode} and {#decode} or use {.delegate_to} to delegate to another object.
  #   They may also implement {#encoded?} if it is possible to efficiently test the
  class Transform
    autoload :Serializer, "moneta/transform/serializer"

    # This helper can be used in subclasses to implement {#encode} and {#decode} by delegating to some other object.  If
    # the object delegated to responds to encode (and optionally decode) or dump (and optionally load), these will be
    # detected automatically.  Otherwise, a second argument can be supplied giving the names of the methods to use as a
    # pair of symbols (encode then optionally decode).
    #
    # @example Delegate to stdlib JSON library
    #   require 'json'
    #
    #   class MyJsonTransform < Moneta::Transform
    #     delegate_to ::JSON
    #     # equvalent to
    #     delegate_to ::JSON, %[dump load]
    #   end
    #
    # @example Delegate to CGI's special escaping methods
    #   require 'json'
    #
    #   class MyEscapeTransform < Moneta::Transform
    #     delegate_to ::CGI, %[escapeURIComponent unescapeURIComponent]
    #   end
    #
    # @param {Module} object The object to delegate to
    # @param {[Symbol,Symbol]} methods The methods on +object+ to delegate to
    def self.delegate_to(object, methods = nil)
      extend Forwardable

      encode, decode =
        if methods && methods.length >= 1
          methods
        elsif object.respond_to?(:encode)
          %i[encode decode]
        elsif object.respond_to?(:dump)
          %i[dump load]
        else
          raise "Could not determine what methods to use on #{object}"
        end

      def_delegator object, encode, :encode

      if decode && object.respond_to?(decode)
        def_delegator object, decode, :decode
      end
    end

    # Transforms can be initialized with arbitrary keyword args.  The default
    # initializer does nothing, just swallows the arguments it receives.
    def initialize(**_)
    end

    # Returns true if the Tranform has a {#decode} method.  Some transforms
    # (e.g. MD5) are one-way.
    def decodable?
      respond_to? :decode
    end

    def method_missing(method, *args)
      case method
      when :encode
        raise NotImplementedError, "Encoder not defined"
      when :decode
        raise NotImplementedError, "Not decodable"
      when :encoded?
        nil
      else
        super
      end
    end

    def respond_to_missing?(method, _)
      method == :encoded?
    end
  end
end
