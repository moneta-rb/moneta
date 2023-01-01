require 'tnetstring'

module Moneta
  module Transforms
    class TNet < Transform
      encode do |value|
        ::TNetstring.dump(value)
      end

      decode do |value|
        ::TNetstring.parse(value).first
      end
    end
  end
end
