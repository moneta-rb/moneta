module Moneta
  # Adds the Ruby Enumerable API
  #
  # @api public
  class Enumerable < Proxy
    include ::Enumerable

    def initialize(adapter, options = {})
      raise "Adapter must support :each_key" unless adapter.supports? :each_key

      super
    end

    def each
      return enum_for(:each) unless block_given?

      each_key do |key|
        yield [key, load(key)]
      end
    end
  end
end
