module Moneta
  # Implements simple create using key? and store.
  #
  # This is sufficient for non-shared stores or if atomicity is not required.
  # @api private
  module CreateSupport
    # (see Defaults#create)
    def create(key, value, options = {})
      if key? key
        false
      else
        store(key, value, options)
        true
      end
    end

    def self.included(base)
      base.supports(:create) if base.respond_to?(:supports)
    end
  end
end
