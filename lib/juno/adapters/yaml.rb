require 'yaml/store'

module Juno
  module Adapters
    # YAML::Store backend
    # @api public
    class YAML < Juno::Adapters::PStore
      protected

      def new_store(options)
        ::YAML::Store.new(options[:file])
      end
    end
  end
end
