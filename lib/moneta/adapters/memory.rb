module Moneta
  module Adapters
    # Memory backend using a hash to store the entries
    # @api public
    class Memory < Base
      include Mixins::IncrementSupport
      include Mixins::HashAdapter
    end
  end
end
