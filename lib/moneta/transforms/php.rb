require 'php_serialize'

module Moneta
  module Transforms
    class PHP < Transform::Serializer
      def initialize(session: false, **options)
        super
        @session = session
      end

      def serialize(value)
        if @session
          ::PHP.serialize_session(value)
        else
          ::PHP.serialize(value)
        end
      end

      def deserialize(value)
        ::PHP.unserialize(value)
      end
    end
  end
end
