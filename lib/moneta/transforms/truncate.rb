require "digest"

module Moneta
  module Transforms
    # Transforms strings by truncating them to a certain fixed length (32 bytes
    # or greater).  Strings that are longer than the specified length will be
    # MD5 hashed, and their last 32 bytes will be replaced by the hash.
    #
    # @example Default behaviour
    #   transform = Moneta::Transforms::Truncate.new
    #   transform.encode('testing') # => 'testing'
    #   transform.encode('t' * 33)  # => 'f58e01819308e77aeb32ffa110da0c58'
    #
    # @example Specifying a longer +maxlen+
    #   transform = Moneta::Transforms::Truncate.new(maxlen: 35)
    #   transform.encode('testing') # => 'testing'
    #   transform.encode('t' * 37)  # => 'ttt910ec89be55ea041c93f624557590410'
    class Truncate < Transform
      # @param maxlen [Numeric] length after which a string will be truncated (must be >= 32)
      def initialize(maxlen: 32, **_)
        super
        raise ":maxlen must be at least 32" if maxlen < 32
        @maxlen = maxlen
      end

      # @param value [String]
      # @return [String]
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
