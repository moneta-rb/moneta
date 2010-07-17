require "moneta/adapters/fog"

module Moneta
  module Adapters
    class Rackspace < Fog

      def initialize(options)
        options[:cloud] = ::Fog::Rackspace::Files
        super
      end

    end
  end
end
