require "qlzruby"

module Moneta
  module Transforms
    # Compresses using the {https://rubygems.org/gems/qlzruby qlzruby gem}
    class QuickLZ < Transform
      delegate_to ::QuickLZ, %i[compress decompress]
    end
  end
end
