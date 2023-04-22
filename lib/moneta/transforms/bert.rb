require "bert"

module Moneta
  module Transforms
    # Encodes text using the {https://rubygems.org/gems/bert bert gem}.
    class BERT < Transform::Serializer
      delegate_to ::BERT
    end
  end
end
