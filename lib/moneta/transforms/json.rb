require "multi_json"

module Moneta
  module Transforms
    # Serializes objects to JSON using the {https://rubygems.org/gems/multi_json multi_json gem}.
    class JSON < Transform::Serializer
      delegate_to ::MultiJson
    end
  end
end
