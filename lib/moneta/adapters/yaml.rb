require 'yaml/store'

module Moneta
  module Adapters
    # YAML::Store backend
    # @api public
    class YAML < PStore
      backend { |file:| ::YAML::Store.new(file) }
    end
  end
end
