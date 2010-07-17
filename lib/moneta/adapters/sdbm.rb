require "sdbm"

module Moneta
  module Adapters
    class SDBM < ::SDBM
      include Moneta::Defaults

      def initialize(options = {})
        raise "No :file options specified" unless file = options[:file]
        super(file)
      end

      def [](key)
        if val = super(key_for(key))
          deserialize(val)
        end
      end

      def store(key, value, *)
        super(key_for(key), serialize(value))
      end

      def key?(key, *)
        super(key_for(key))
      end

      def delete(key, *)
        if val = super(key_for(key))
          deserialize(val)
        end
      end
    end
  end
end
