require 'yaml/store'

module Moneta
  module Adapters
    # YAML::Store backend
    # @api public
    class YAML < Moneta::Adapters::PStore
      protected

      def new_store(options)
        ::YAML::Store.new(options[:file])
      end
    end
  end
end
