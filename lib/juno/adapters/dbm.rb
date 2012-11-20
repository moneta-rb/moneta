require 'dbm'

module Juno
  module Adapters
    class DBM < Memory
      def initialize(options = {})
        raise 'No option :file specified' unless options[:file]
        @memory = ::DBM.new(options[:file])
      end

      def close
        @memory.close
        nil
      end
    end
  end
end
