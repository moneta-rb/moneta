module Moneta
  class Transform
    # A Serializer is a special type of Transform intended for serializing objects to text.  Moneta has historically
    # distinguished serializers from other transforms by only transforming non-string values, which is still be default
    # behaviour of this class, though it can be disabled (i.e. to apply serialization to everything) by initializing
    # with +serialize_unless_string+ set to +false+.
    #
    # Because of the above behaviour, serializers are by default not decodable, because it is pretty much impossible to
    # tell for some given string whether it was originally a string, or if it was encoded.  Setting
    # +serialize_unless_string+ will enable decoding.
    #
    # @abstract Subclasses should implement {#serialize} and optionally {#deserialize}; or use
    #   {Moneta::Transform::Serializer.delegate_to}. They may also implement {#encoded?} if it is possible to
    #   efficiently test whether something was encoded (e.g. using a magic number).
    class Serializer < Transform
      # This helper can be used in subclasses to implement {#serialize} and {#deserialize}, similar to
      # {Moneta::Transform.delegate_to}.  {#deserialize} is optional - if not delegated or implemented, the transform
      # will be unserializable.
      #
      # @example Delegate to stdlib JSON library
      #   require 'json'
      #
      #   # By inheriting from Serializer, this class will by default only serialize to JSON when the input is not a
      #   # string
      #   class MyJsonSerializer < Moneta::Transform::Serializer
      #     delegate_to ::JSON
      #     # equvalent to
      #     delegate_to ::JSON, %[dump load]
      #   end
      #
      #   serializer1 = MyJsonSerializer.new
      #   serializer2 = MyJsonSerializer.new(serialize_unless_string: false)
      #
      #   serializer1.encode('test')    #=> 'test'
      #   serializer1.encode(%w[1 2 3]) #=> '["1","2","3"]'
      #   serializer1.decode('test')    #=> NotImplementedError
      #   serializer2.encode('test')    #=> '"test"'
      #   serializer2.decode('"test"')  #=> 'test'
      #
      # @param object [Module] The object to delegate to
      # @param methods [<Symbol,Symbol>] The methods on +object+ to delegate to
      def self.delegate_to(object, methods = nil)
        extend Forwardable

        serialize, deserialize =
          if methods && methods.length >= 1
            methods
          elsif object.respond_to?(:encode)
            %i[encode decode]
          elsif object.respond_to?(:dump)
            %i[dump load]
          else
            raise "Could not determine what methods to use on #{object}"
          end

        def_delegator object, serialize, :serialize

        if deserialize && object.respond_to?(deserialize)
          def_delegator object, deserialize, :deserialize
        end
      end

      # Serializers implement {#encode} and {#decode} based on the subclass' implementation of {#serialize} and
      # {#deserialize}, and using the +serialize_unless_string+ option.  If it's enabled, then {#encode} will only call
      # {#serialize} if the input is not a string.
      #
      # @param serialize_unless_string [Boolean] Whether to skip serialization of strings
      def initialize(serialize_unless_string: false, **_)
        super
        @serialize_unless_string = serialize_unless_string
      end

      # Calls {#serialize} provided that either the +serialize_unless_string+ option was disabled, or the input is not a
      # string.
      #
      # @param value [Object] object to encode
      # @return [String] The serialized string
      def encode(value)
        if @serialize_unless_string && String === value
          value
        else
          serialize(value)
        end
      end

      # Calls {#deserialize} if implemented and if +serialize_unless_string+ was disabled
      #
      # @param value [String] object to decode
      # @return [Object] the decoded object
      # @raise [NotImplementedError] if this serializer cannot do deserialization
      def decode(value)
        raise NotImplementedError, "cannot decode in serialize_unless_string mode" if @serialize_unless_string
        deserialize(value)
      end

      # Returns true iff the class has implemented {#deserialize} and is not running in +serialize_unless_string+ mode.
      #
      # @return [Boolean]
      def decodable?
        !@serialize_unless_string && respond_to?(:deserialize)
      end
    end
  end
end
