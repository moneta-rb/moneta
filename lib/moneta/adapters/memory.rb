module Moneta
  module Adapters
    class Memory < Hash
      include Moneta::Defaults

      def [](key)
        deserialize(super(key_for(key)))
      end

      def key?(key, *)
        super(key_for(key))
      end

      def store(key, value, *args)
        super(key_for(key), serialize(value), *args)
      end

      def delete(key, *args)
        deserialize(super(key_for(key), *args))
      end
    end
  end
end
