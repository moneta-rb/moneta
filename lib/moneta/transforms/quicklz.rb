require 'qlzruby'

module Moneta
  module Transforms
    class QuickLZ < Transform
      delegate_to ::QuickLZ, %i[compress decompress]
    end
  end
end
