require "digest"

module Moneta
  module Transforms
    class Truncate < Transform
      def initialize(maxlen: 32, **_)
        super
        @maxlen = maxlen
      end

      def encode(value)
        if value.size >= @maxlen
          digest = ::Digest::MD5.hexdigest(value)
          value[0, @maxlen - digest.size] << digest
        else
          value
        end
      end
    end
  end
end
