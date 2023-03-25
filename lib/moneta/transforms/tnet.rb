require 'tnetstring'

module Moneta
  module Transforms
    class TNet < Transform
      def encode(value)
        ::TNetstring.dump(value)
      end

      def decode(value)
        ::TNetstring.parse(value).first
      end
    end
  end
end
