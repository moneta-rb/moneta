module Moneta
  # This mixin handles the calculation of expiration times.
  #
  #
  module ExpiresSupport
    attr_accessor :default_expires

    protected

    # Calculates the time when something will expire.
    #
    # This method considers false and 0 as "no-expire" and every positive
    # number as a time to live in seconds.
    #
    # @param [Hash] options Options hash
    # @option options [0,false,nil,Numeric] :expires expires value given by user
    # @param [0,false,nil,Numeric] default default expiration time
    #
    # @return [false] if it should not expire
    # @return [Time] the time when something should expire
    # @return [nil] if it is not known
    def expires_at(options, default = @default_expires)
      value = expires_value(options, default)
      Numeric === value ? Time.now + value : value
    end

    # Calculates the number of seconds something should last.
    #
    # This method considers false and 0 as "no-expire" and every positive
    # number as a time to live in seconds.
    #
    # @param [Hash] options Options hash
    # @option options [0,false,nil,Numeric] :expires expires value given by user
    # @param [0,false,nil,Numeric] default default expiration time
    #
    # @return [false] if it should not expire
    # @return [Numeric] seconds until expiration
    # @return [nil] if it is not known
    def expires_value(options, default = @default_expires)
      case value = options[:expires]
      when 0, false
        false
      when nil
        default ? default.to_r : nil
      when Numeric
        value = value.to_r
        raise ArgumentError, ":expires must be a positive value, got #{value}" if value < 0
        value
      else
        raise ArgumentError, ":expires must be Numeric or false, got #{value.inspect}"
      end
    end

    class << self
      def included(base)
        base.supports(:expires) if base.respond_to?(:supports)
      end
    end
  end
end
