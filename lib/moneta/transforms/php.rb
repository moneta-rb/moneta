require "php_serialize"

module Moneta
  module Transforms
    # Serializes objects to strings using the {https://rubygems.org/gems/php_serialize php_serialize gem}.  This uses
    # PHP's serialization format(s), as described in {https://www.php.net/manual/en/language.oop5.serialization.php}.
    #
    # When initialized with the +session+ option, it will use PHP's slightly more restricted session serialization
    # format instead. See {https://www.php.net/manual/en/function.session-encode.php}.
    #
    # @example Normal vs Session format
    #   Moneta::Transforms::PHP.new.encode({'test' => 1})                # => "a:1:{s:4:\"test\";i:1;}"
    #   Moneta::Transforms::PHP.new(session: true).encode({'test' => 1}) # => "test|i:1;"
    class PHP < Transform::Serializer
      # @param session [Boolean] when +true+, objects are serialized using PHP's session serialization format instead,
      # which is roughly the same
      # @see
      def initialize(session: false, **options)
        super
        @session = session
      end

      # Serializes to PHP format
      #
      # @param value [Object]
      # @return [String]
      def serialize(value)
        if @session
          ::PHP.serialize_session(value)
        else
          ::PHP.serialize(value)
        end
      end

      # Deserializes from PHP format
      #
      # @param value [Object]
      # @return [String]
      def deserialize(value)
        ::PHP.unserialize(value)
      end
    end
  end
end
