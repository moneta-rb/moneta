require 'bert'

module Moneta
  module Transforms
    class BERT < Transform
      delegate_to ::BERT
    end
  end
end
