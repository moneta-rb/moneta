require 'set'

module Moneta
  # Some docs here
  module Config
    # @api private
    module ClassMethods
      def config(name, coerce: nil, default: nil, required: false, &block)
        raise ArgumentError, 'name must be a symbol' unless Symbol === name

        defaults = config_defaults

        raise ArgumentError, "#{name} is already a config option" if defaults.key?(name)
        raise ArgumentError, "coerce must respond to :to_proc" if coerce && !coerce.respond_to?(:to_proc)

        defaults.merge!(name => default.freeze).freeze
        instance_variable_set :@config_defaults, defaults

        instance_variable_set :@config_coercions, config_coercions.merge!(name => coerce.to_proc) if coerce
        instance_variable_set :@config_required_keys, config_required_keys.add(name).freeze if required
        instance_variable_set :@config_blocks, config_blocks.merge!(name => block) if block
      end

      def config_variable(name)
        if instance_variable_defined?(name)
          instance_variable_get(name).dup
        elsif superclass.respond_to?(:config_variable)
          superclass.config_variable(name)
        end
      end

      def config_defaults
        config_variable(:@config_defaults) || {}
      end

      def config_required_keys
        config_variable(:@config_required_keys) || Set.new
      end

      def config_coercions
        config_variable(:@config_coercions) || {}
      end

      def config_blocks
        config_variable(:@config_blocks) || {}
      end

      def config_struct
        unless @config_struct
          keys = config_defaults.keys
          @config_struct = Struct.new(*keys) unless keys.empty?
        end

        @config_struct
      end
    end

    def config
      raise "Not configured" unless defined?(@config)
      @config
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    protected

    def configure(**options)
      raise 'Already configured' if defined?(@config)

      self.class.config_required_keys.each do |key|
        raise ArgumentError, "#{key} is required" unless options.key? key
      end

      defaults = self.class.config_defaults

      overrides, remainder = options
        .partition { |key,| defaults.key? key }
        .map { |pairs| pairs.to_h }

      self.class.config_coercions.each do |key, coerce|
        overrides[key] = coerce.call(overrides[key]) if overrides.key?(key)
      end

      overridden = defaults.merge!(overrides)

      config_blocks = self.class.config_blocks
      values = overridden.map do |key, value|
        if config_block = config_blocks[key]
          instance_exec(**overridden, &config_block)
        else
          value
        end
      end

      @config = self.class.config_struct&.new(*values).freeze
      remainder
    end
  end
end
