module Moneta
  # This is for adapters that conform to the DBM interface
  # @api private
  module DBMAdapter
    include HashAdapter

    # (see Proxy#close)
    def close
      @backend.close
      nil
    end

    # (see Proxy#merge!)
    def merge!(pairs, options = {})
      hash =
        if block_given?
          keys = pairs.map { |k, _| k }
          old_pairs = Hash[slice(*keys)]
          Hash[pairs.map do |key, new_value|
            new_value = yield(key, old_pairs[key], new_value) if old_pairs.key?(key)
            [key, new_value]
          end.to_a]
        else
          Hash === pairs ? pairs : Hash[pairs.to_a]
        end

      @backend.update(hash)
      self
    end
  end
end
