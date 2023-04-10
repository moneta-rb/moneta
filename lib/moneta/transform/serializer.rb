module Moneta
  class Transform
    class Serializer < Transform
      class << self
        def delegate_to(object, methods = nil)
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
      end

      def initialize(serialize_unless_string: false, **_)
        super
        @serialize_unless_string = serialize_unless_string
      end

      def encode(value)
        if @serialize_unless_string && String === value
          value
        else
          serialize(value)
        end
      end

      def decode(value)
        raise NotImplementedError, "cannot decode in serialize_unless_string mode" if @serialize_unless_string
        deserialize(value)
      end

      def decodable?
        !@serialize_unless_string && respond_to?(:deserialize)
      end
    end
  end
end
