require "digest/rmd160"

module Moneta
  module Transforms
    # Hashes strings using RIPEMD RMD160.
    #
    # The strings are hex-encoded.
    #
    # @see https://homes.esat.kuleuven.be/~bosselae/ripemd160.html
    # @example
    #   Moneta::Transforms::RMD160.new.encode('test') # => "5e52fee47e6b070565f74372468cdc699de89107"
    class RMD160 < Transform
      delegate_to ::Digest::RMD160, %i[hexdigest]
    end
  end
end
