require 'php_serialize'

module Moneta
  module Transforms
    class PHP < Transform
      def initialize(session: false, **options)
        super(decodable: true)
        @session = session
      end

      def encode(value)
        if @session
          ::PHP.serialize_session(value)
        else
          ::PHP.serialize(value)
        end
      end

      def decode(value)
        ::PHP.unserialize(value)
      end
    end
  end
end
