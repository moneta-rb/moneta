module Moneta
  class Transformer
    module Helper
      # @api private
      module BSON
        extend self

        def load(value)
          ::BSON::Document.from_bson(::BSON::ByteBuffer.new(value))['v']
        end

        def dump(value)
          ::BSON::Document['v' => value].to_bson.to_s
        end
      end
    end
  end
end
