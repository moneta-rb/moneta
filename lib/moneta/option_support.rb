module Moneta
  # @api private
  module OptionSupport
    # Return Moneta store with default options or additional proxies
    #
    # @param [Hash] options Options to merge
    # @return [Moneta store]
    #
    # @api public
    def with(options = nil, &block)
      adapter = self
      if block
        builder = Builder.new(&block)
        builder.adapter(adapter)
        adapter = builder.build.last
      end
      options ? OptionMerger.new(adapter, options) : adapter
    end

    # Return Moneta store with default option raw: true
    #
    # @return [OptionMerger]
    # @api public
    def raw
      @raw ||=
        begin
          store = with(raw: true, only: [:load, :store, :create, :delete])
          store.instance_variable_set(:@raw, store)
          store
        end
    end

    # Return Moneta store with default prefix option
    #
    # @param [String] prefix Key prefix
    # @return [OptionMerger]
    # @api public
    def prefix(prefix)
      with(prefix: prefix, except: :clear)
    end

    # Return Moneta store with default expiration time
    #
    # @param [Integer] expires Default expiration time
    # @return [OptionMerger]
    # @api public
    def expires(expires)
      with(expires: expires, only: [:store, :create, :increment])
    end
  end
end
