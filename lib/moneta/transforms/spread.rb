module Moneta
  module Transforms
    # Transforms strings by inserting a "/" character after the first two
    # characters, using {File.join}.  This can be used with the
    # {Adapters::File} adapter to spread files into subdirectories.  The
    # +:HashFile+ option on {Moneta.new} uses this transform (in conjunction
    # with {MD5}) - see {file:README.md}.
    #
    # @example
    #   transform = Moneta::Transforms::Spread.new
    #   transform.encode('testing')  # => 'te/sting'
    #   transform.encode('te/sting') # => 'te/sting'
    #   transform.encode('tes/ting') # => 'te/s/ting'
    class Spread < Transform
      # @param value [String]
      # @return [String]
      def encode(value)
        ::File.join(value[0..1], value [2..-1])
      end
    end
  end
end
