module Moneta
  # Transforms keys and values (Marshal, YAML, JSON, Base64, MD5, ...).
  # You can bypass the transformer (e.g. serialization) by using the `:raw` option.
  #
  # @example Add `Moneta::Transformer` to proxy stack
  #   Moneta.build do
  #     transformer key: [:marshal, :escape], value: [:marshal]
  #     adapter :File, dir: 'data'
  #   end
  #
  # @example Bypass serialization
  #   store.store('key', 'value', raw: true)
  #   store['key'] # raises an Exception
  #   store.load('key', raw: true) # returns 'value'
  #
  #   store['key'] = 'value'
  #   store.load('key', raw: true) # returns "\x04\bI\"\nvalue\x06:\x06ET"
  #
  # @api public
  class Transformer < Proxy
    class << self
      alias original_new new

      # @param [Moneta store] adapter The underlying store
      # @param [Hash] options
      # @return [Transformer] new Moneta transformer
      # @option options [Array] :key List of key transformers in the order in which they should be applied
      # @option options [Array] :value List of value transformers in the order in which they should be applied
      # @option options [String] :prefix Prefix string for key namespacing (Used by the :prefix key transformer)
      # @option options [String] :secret HMAC secret to verify values (Used by the :hmac value transformer)
      # @option options [Integer] :maxlen Maximum key length (Used by the :truncate key transformer)
      def new(adapter, options = {})
        keys = [options[:key]].flatten.compact
        values = [options[:value]].flatten.compact
        raise ArgumentError, 'Option :key or :value is required' if keys.empty? && values.empty?
        options[:prefix] ||= '' if keys.include?(:prefix)
        name = class_name(keys, values)
        const_set(name, compile(keys, values)) unless const_defined?(name)
        const_get(name).original_new(adapter, options)
      end

      private

      def compile(keys, values)
        @key_validator ||= compile_validator(KEY_TRANSFORMER)
        @load_key_validator ||= compile_validator(LOAD_KEY_TRANSFORMER)
        @test_key_validator ||= compile_validator(TEST_KEY_TRANSFORMER)
        @value_validator ||= compile_validator(VALUE_TRANSFORMER)

        raise ArgumentError, 'Invalid key transformer chain' if @key_validator !~ keys.map(&:inspect).join
        raise ArgumentError, 'Invalid value transformer chain' if @value_validator !~ values.map(&:inspect).join

        klass = Class.new(self)
        compile_each_key_support_clause(klass, keys)
        klass.class_eval <<-END_EVAL, __FILE__, __LINE__ + 1
          def initialize(adapter, options = {})
            super
            #{compile_initializer('key', keys)}
            #{compile_initializer('value', values)}
          end
        END_EVAL

        key, key_opts = compile_transformer(keys, 'key')
        key_load, key_load_opts = compile_transformer(keys.reverse, 'key', 1) if @load_key_validator =~ keys.map(&:inspect).join
        key_test, key_test_opts = compile_transformer(keys.reverse, 'key', 4) if @test_key_validator =~ keys.map(&:inspect).join
        dump, dump_opts = compile_transformer(values, 'value')
        load, load_opts = compile_transformer(values.reverse, 'value', 1)

        if values.empty?
          compile_key_transformer(klass, key, key_opts, key_load, key_load_opts, key_test, key_test_opts)
        elsif keys.empty?
          compile_value_transformer(klass, load, load_opts, dump, dump_opts)
        else
          compile_key_value_transformer(klass, key, key_opts, key_load, key_load_opts, key_test, key_test_opts, load, load_opts, dump, dump_opts)
        end

        klass
      end

      def without(*options)
        options = options.flatten.uniq
        options.empty? ? 'options' : "Utils.without(options, #{options.map(&:to_sym).map(&:inspect).join(', ')})"
      end

      def compile_each_key_support_clause(klass, keys)
        klass.class_eval <<-END_EVAL, __FILE__, __LINE__ + 1
          #{'not_supports :each_key' if @load_key_validator !~ keys.map(&:inspect).join}
        END_EVAL
      end

      def compile_key_transformer(klass, key, key_opts, key_load, key_load_opts, key_test, key_test_opts)
        if_key_test = key_load && key_test ? "if #{key_test}" : ''

        klass.class_eval <<-END_EVAL, __FILE__, __LINE__ + 1
          def key?(key, options = {})
            @adapter.key?(#{key}, #{without key_opts})
          end
          def each_key(&block)
            raise NotImplementedError, "each_key is not supported on this transformer" \
              unless supports? :each_key

            return enum_for(:each_key) unless block_given?
            @adapter.each_key.lazy.map{ |key| #{key_load} #{if_key_test} }.reject(&:nil?).each(&block)

            self
          end
          def increment(key, amount = 1, options = {})
            @adapter.increment(#{key}, amount, #{without key_opts})
          end
          def load(key, options = {})
            @adapter.load(#{key}, #{without :raw, key_opts})
          end
          def store(key, value, options = {})
            @adapter.store(#{key}, value, #{without :raw, key_opts})
          end
          def delete(key, options = {})
            @adapter.delete(#{key}, #{without :raw, key_opts})
          end
          def create(key, value, options = {})
            @adapter.create(#{key}, value, #{without :raw, key_opts})
          end
          def values_at(*keys, **options)
            t_keys = keys.map { |key| #{key} }
            @adapter.values_at(*t_keys, **#{without :raw, key_opts})
          end
          def fetch_values(*keys, **options)
            t_keys = keys.map { |key| #{key} }

            block = if block_given?
                      key_lookup = Hash[t_keys.zip(keys)]
                      lambda { |t_key| yield key_lookup[t_key] }
                    end
            @adapter.fetch_values(*t_keys, **#{without :raw, key_opts}, &block)
          end
          def slice(*keys, **options)
            t_keys = keys.map { |key| #{key} }
            key_lookup = Hash[t_keys.zip(keys)]
            @adapter.slice(*t_keys, **#{without :raw, key_opts}).map do |key, value|
              [key_lookup[key], value]
            end
          end
          def merge!(pairs, options = {})
            keys, values = pairs.to_a.transpose
            t_keys = keys.map { |key| #{key} }
            block = if block_given?
                      key_lookup = Hash[t_keys.zip(keys)]
                      lambda { |k, old, new| yield(key_lookup[k], old, new) }
                    end
            @adapter.merge!(t_keys.zip(values), #{without :raw, key_opts}, &block)
            self
          end
        END_EVAL
      end

      def compile_value_transformer(klass, load, load_opts, dump, dump_opts)
        klass.class_eval <<-END_EVAL, __FILE__, __LINE__ + 1
          def load(key, options = {})
            value = @adapter.load(key, #{without :raw, load_opts})
            value && !options[:raw] ? #{load} : value
          end
          def store(key, value, options = {})
            @adapter.store(key, options[:raw] ? value : #{dump}, #{without :raw, dump_opts})
            value
          end
          def delete(key, options = {})
            value = @adapter.delete(key, #{without :raw, load_opts})
            value && !options[:raw] ? #{load} : value
          end
          def create(key, value, options = {})
            @adapter.create(key, options[:raw] ? value : #{dump}, #{without :raw, dump_opts})
          end
          def values_at(*keys, **options)
            values = @adapter.values_at(*keys, **#{without :raw, load_opts})
            values.map do |value|
              value && !options[:raw] ? #{load} : value
            end
          end
          def fetch_values(*keys, **options, &orig_block)
            substituted = {}
            block = if block_given?
                      lambda { |key| substituted[key] = true; yield key }
                    end

            values = @adapter.fetch_values(*keys, **#{without :raw, load_opts}, &block)
            if options[:raw]
              values
            else
              keys.map(&substituted.method(:key?)).zip(values).map do |substituted, value|
                if substituted || !value
                  value
                else
                  #{load}
                end
              end
            end
          end
          def slice(*keys, **options)
            @adapter.slice(*keys, **#{without :raw, load_opts}).map do |key, value|
              [key, value && !options[:raw] ? #{load} : value]
            end
          end
          def merge!(pairs, options = {}, &orig_block)
            block = if block_given?
                      if options[:raw]
                        orig_block
                      else
                        lambda do |k, old_val, new_val|
                          value = old_val; old_val = #{load}
                          value = new_val; new_val = #{load}
                          value = yield(k, old_val, new_val)
                          #{dump}
                        end
                      end
                    end

            t_pairs = options[:raw] ? pairs : pairs.map { |key, value| [key, #{dump}] }
            @adapter.merge!(t_pairs, #{without :raw, dump_opts}, &block)
            self
          end
        END_EVAL
      end

      def compile_key_value_transformer(klass, key, key_opts, key_load, key_load_opts, key_test, key_test_opts, load, load_opts, dump, dump_opts)
        if_key_test = key_load && key_test ? "if #{key_test}" : ''

        klass.class_eval <<-END_EVAL, __FILE__, __LINE__ + 1
          def key?(key, options = {})
            @adapter.key?(#{key}, #{without key_opts})
          end
          def each_key(&block)
            raise NotImplementedError, "each_key is not supported on this transformer" \
              unless supports? :each_key

            return enum_for(:each_key) { @adapter.each_key.size } unless block_given?
            @adapter.each_key.lazy.map{ |key| #{key_load} #{if_key_test} }.reject(&:nil?).each(&block)

            self
          end
          def increment(key, amount = 1, options = {})
            @adapter.increment(#{key}, amount, #{without key_opts})
          end
          def load(key, options = {})
            value = @adapter.load(#{key}, #{without :raw, key_opts, load_opts})
            value && !options[:raw] ? #{load} : value
          end
          def store(key, value, options = {})
            @adapter.store(#{key}, options[:raw] ? value : #{dump}, #{without :raw, key_opts, dump_opts})
            value
          end
          def delete(key, options = {})
            value = @adapter.delete(#{key}, #{without :raw, key_opts, load_opts})
            value && !options[:raw] ? #{load} : value
          end
          def create(key, value, options = {})
            @adapter.create(#{key}, options[:raw] ? value : #{dump}, #{without :raw, key_opts, dump_opts})
          end
          def values_at(*keys, **options)
            t_keys = keys.map { |key| #{key} }
            values = @adapter.values_at(*t_keys, **#{without :raw, key_opts, load_opts})
            values.map do |value|
              value && !options[:raw] ? #{load} : value
            end
          end
          def fetch_values(*keys, **options)
            t_keys = keys.map { |key| #{key} }
            key_lookup = Hash[t_keys.zip(keys)]
            substituted = {}
            block = if block_given?
                      lambda do |t_key|
                        key = key_lookup[t_key]
                        substituted[key] = true
                        yield key
                      end
                    end

            values = @adapter.fetch_values(*t_keys, **#{without :raw, key_opts, load_opts}, &block)

            if options[:raw]
              values
            else
              keys.map(&substituted.method(:key?)).zip(values).map do |substituted, value|
                if substituted || !value
                  value
                else
                  #{load}
                end
              end
            end
          end
          def slice(*keys, **options)
            t_keys = keys.map { |key| #{key} }
            key_lookup = Hash[t_keys.zip(keys)]
            @adapter.slice(*t_keys, **#{without :raw, key_opts, load_opts}).map do |key, value|
              [key_lookup[key], value && !options[:raw] ? #{load} : value]
            end
          end
          def merge!(pairs, options = {})
            keys, values = pairs.to_a.transpose
            t_keys = keys.map { |key| #{key} }
            key_lookup = Hash[t_keys.zip(keys)]

            block = if block_given?
                      if options[:raw]
                        lambda do |k, old_val, new_val|
                          yield(key_lookup[k], old_val, new_val)
                        end
                      else
                        lambda do |k, old_val, new_val|
                          value = old_val; old_val = #{load}
                          value = new_val; new_val = #{load}
                          value = yield(key_lookup[k], old_val, new_val)
                          #{dump}
                        end
                      end
                    end
            t_pairs = if options[:raw]
                        t_keys.zip(values)
                      else
                        t_keys.zip(values.map { |value| #{dump} })
                      end
            @adapter.merge!(t_pairs, #{without :raw, key_opts, dump_opts}, &block)
            self
          end
        END_EVAL
      end

      # Compile option initializer
      def compile_initializer(type, transformers)
        transformers.map do |name|
          t = TRANSFORMER[name]
          (t[1].to_s + t[2].to_s).scan(/@\w+/).uniq.map do |opt|
            "raise ArgumentError, \"Option #{opt[1..-1]} is required for #{name} #{type} transformer\" unless #{opt} = options[:#{opt[1..-1]}]\n"
          end
        end.join("\n")
      end

      def compile_validator(str)
        Regexp.new('\A' +
                   str.gsub(/\w+/) do
                     '(' + TRANSFORMER.select { |_, v| v.first.to_s == $& }.map { |v| ":#{v.first}" }.join('|') + ')'
                   end.gsub(/\s+/, '') +
                   '\Z')
      end

      # Returned compiled transformer code string
      def compile_transformer(transformer, var, idx = 2)
        value, options = var, []
        transformer.each do |name|
          raise ArgumentError, "Unknown transformer #{name}" unless t = TRANSFORMER[name]
          require t[3] if t[3]
          code = t[idx]
          code ||= compile_prefix(name: name, transformer: t, value: value) if idx == 4 && var == 'key'

          raise "Undefined command for transformer #{name}" unless code

          options += code.scan(/options\[:(\w+)\]/).flatten
          value =
            if t[0] == :serialize && var == 'key' && idx == 4
              "(tmp = #{value}; (false === tmp || '' === tmp) ? false : #{code % 'tmp'})"
            elsif t[0] == :serialize && var == 'key'
              "(tmp = #{value}; String === tmp ? tmp : #{code % 'tmp'})"
            else
              code % value
            end
        end
        [value, options]
      end

      def class_name(keys, values)
        camel_case = lambda { |sym| sym.to_s.split('_').map(&:capitalize).join }
        (keys.empty? ? '' : keys.map(&camel_case).join + 'Key') +
          (values.empty? ? '' : values.map(&camel_case).join + 'Value')
      end

      def compile_prefix(name:, transformer:, value:)
        return unless [:encode, :serialize].include?(transformer[0])

        load_val, = compile_transformer([name], value, 1)
        "(#{load_val} rescue '')"
      end
    end
  end
end

require 'moneta/transformer/helper'
require 'moneta/transformer/config'
