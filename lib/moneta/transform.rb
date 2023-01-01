require 'forwardable'

module Moneta
  class Transform
    class << self
      attr_reader :encoder, :decoder, :test_encoding

      def encode(proc = nil, &block)
        @encoder = proc || block
      end

      def decode(proc = nil, &block)
        @decoder = proc || block
        decodable!
      end

      def decodable!
        @decodable = true
      end

      def decodable?
        @decodable || false
      end

      def encoding_test(proc = nil, &block)
        @test_encoding = proc || block
      end

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
          decodable!
        end
      end
    end

    def initialize(decodable: self.class.decodable?, **_)
      @decodable = decodable
    end

    def encode(value)
      encoder = self.class.encoder
      raise "Encoder not defined" unless encoder
      encoder.call(value)
    end

    def decodable?
      @decodable || self.class.decodable?
    end

    def decode(value)
      raise "Not decodable" unless decodable?
      self.class.decoder.call(value)
    end

    def encoded?(value)
      if self.class.test_encoding
        self.class.test_encoding.call(value)
      end
    end
  end
end
