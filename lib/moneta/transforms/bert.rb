require 'bert'

module Moneta
  module Transforms
    class BERT < Transform::Serializer
      delegate_to ::BERT
    end
  end
end
