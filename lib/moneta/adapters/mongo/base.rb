module Moneta
  module Adapters
    # @api private
    class MongoBase
      include Defaults
      include ExpiresSupport

      supports :create, :increment
      attr_reader :backend

      DEFAULT_PORT = 27017

      def initialize(options = {})
        self.default_expires = options.delete(:expires)
        @expires_field = options.delete(:expires_field) || 'expiresAt'
        @value_field = options.delete(:value_field) || 'value'
        @type_field = options.delete(:type_field) || 'type'
      end

      protected

      def doc_to_value(doc)
        case doc[@type_field]
        when 'Hash'
          doc = doc.dup
          doc.delete('_id')
          doc.delete(@type_field)
          doc.delete(@expires_field)
          doc
        when 'Number'
          doc[@value_field]
        else
          doc[@value_field].to_s
        end
      end

      def value_to_doc(key, value, options)
        case value
        when Hash
          value.merge('_id' => key,
                      @type_field => 'Hash',
                      # @expires_field must be a Time object (BSON date datatype)
                      @expires_field => expires_at(options) || nil)
        when Float, Fixnum
          { '_id' => key,
            @type_field => 'Number',
            @value_field => value,
            # @expires_field must be a Time object (BSON date datatype)
            @expires_field => expires_at(options) || nil }
        when String
          intvalue = value.to_i
          { '_id' => key,
            @type_field => 'String',
            @value_field => intvalue.to_s == value ? intvalue : to_binary(value),
            # @expires_field must be a Time object (BSON date datatype)
            @expires_field => expires_at(options) || nil }
        else
          raise ArgumentError, "Invalid value type: #{value.class}"
        end
      end
    end
  end
end
