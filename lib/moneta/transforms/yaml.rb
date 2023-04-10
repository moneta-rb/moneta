require 'yaml'

module Moneta
  module Transforms
    class YAML < Transform::Serializer
      def initialize(safe: false, **options)
        super
        @load_method =
          if safe
            ::YAML.method(:safe_load)
          else
            ::YAML.respond_to?(:unsafe_load) ? ::YAML.method(:unsafe_load) : ::YAML.method(:load)
          end

        @load_positional_options, @load_keyword_options = setup_yaml_options(@load_method, options)

        @dump_method =
          if safe && ::YAML.respond_to?(:safe_dump)
            ::YAML.method(:safe_dump)
          else
            ::YAML.method(:dump)
          end

        @dump_positional_options, @dump_keyword_options = setup_yaml_options(@dump_method, options)
      end

      def serialize(value)
        @dump_method.call(value, *@dump_positional_options, **@dump_keyword_options)
      end

      def deserialize(value)
        @load_method.call(value, *@load_positional_options, **@load_keyword_options)
      end

      private

      def setup_yaml_options(method, options)
        positional_option_names = method.parameters
          .select { |type, _| type == :opt }
          .map { |_, name| name }

        keyword_option_names = method.parameters
          .select { |type, _| type == :key }
          .map { |_, name| name }

        positional_options = options.values_at(positional_option_names)
        positional_options.pop while !positional_options.empty? && positional_options.last == nil

        keyword_options = options.select { |key, _| keyword_option_names.include?(key) }

        [positional_options, keyword_options]
      end
    end
  end
end
