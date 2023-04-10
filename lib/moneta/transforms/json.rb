require 'multi_json'

module Moneta
  module Transforms
    class JSON < Transform::Serializer
      delegate_to ::MultiJson
    end
  end
end
