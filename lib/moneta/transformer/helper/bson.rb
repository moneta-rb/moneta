module Moneta
  class Transformer
    module Helper::BSON
      extend self

      if ::BSON::VERSION >= '4.0.0'
        def load value
          ::BSON::Document.from_bson(::BSON::ByteBuffer.new(value))['v']
        end

        def dump value
          ::BSON::Document['v'=>value].to_bson.to_s
        end
      else
        def load value
          ::BSON::Document.from_bson(::StringIO.new(value))['v']
        end

        def dump value
          ::BSON::Document['v'=>value].to_bson
        end
      end
    end
  end
end
