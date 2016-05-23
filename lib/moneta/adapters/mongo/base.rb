require 'bson'

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
          # In ruby_bson version 2 (and probably up), #to_s no longer returns the binary data
          if doc[@value_field].is_a? ::BSON::Binary and defined? ::BSON::VERSION and ::BSON::VERSION[0].to_i >= 2
            doc[@value_field].data
          else
            doc[@value_field].to_s
          end
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

      # BSON will use String#force_encoding to make the string 8-bit
      # ASCII.  This could break unicode text so we should dup in this
      # case, and it also fails with frozen strings.
      def to_binary(s)
        s = s.dup if s.frozen? || s.encoding != Encoding::ASCII_8BIT
        ::BSON::Binary.new(s)
      end
    end
  end
end
