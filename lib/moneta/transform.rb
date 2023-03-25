require 'forwardable'

module Moneta
  class Transform
    class << self
      attr_reader :encoder, :decoder, :test_encoding

      def delegate_to(object, methods = nil)
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
    end

    def initialize(**_); end

    def decodable?
      respond_to? :decode
    end

    def method_missing(method, *args)
      case method
      when :encode
        raise "Encoder not defined"
      when :decode
        raise "Not decodable"
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
