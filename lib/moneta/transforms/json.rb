require 'multi_json'

module Moneta
  module Transforms
    class JSON < Transform
      delegate_to ::MultiJson
    end
  end
end
