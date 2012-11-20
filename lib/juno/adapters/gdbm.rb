require 'gdbm'

module Juno
  module Adapters
    class GDBM < Memory
      def initialize(options = {})
        raise 'No option :file specified' unless options[:file]
        @memory = ::GDBM.new(options[:file])
      end

      def close
        @memory.close
        nil
      end
    end
  end
end
