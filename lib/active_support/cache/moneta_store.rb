module ActiveSupport
  module Cache
    # @api public
    class MonetaStore < Store
      def initialize(options = nil)
        raise ArgumentError, 'Option :store is required' unless @store = options.delete(:store)
        @store = ::Moneta.new(@store, expires: true) if Symbol === @store
        super(options)
        extend Strategy::LocalCache
      end

      def increment(key, amount = 1, options = nil)
        options = merged_options(options)
        instrument(:increment, key, amount: amount) do
          @store.increment(normalize_key(key, options), amount, moneta_options(options))
        end
      end

      def decrement(key, amount = 1, options = nil)
        options = merged_options(options)
        instrument(:decrement, key, amount: amount) do
          @store.increment(normalize_key(key, options), -amount, moneta_options(options))
        end
      end

      def clear(options = nil)
        options = merged_options(options)
        instrument(:clear, nil, nil) do
          @store.clear(moneta_options(options))
        end
      end

      # This prevents underlying Moneta transformers from erroring on raw values
      def exist?(name, options = {})
        super
      rescue
        super(name, options.merge(raw: true))
      end

      # These are the rails 5.2 versions of these methods, which call into the
      # lower-level read_multi_entries and write_multi_entries methods.  We
      # define them here only if the superclass versions don't use the *_entries
      # methods.
      unless [:read_multi_entries, :write_multi_entries].all? { |m| superclass.private_instance_methods.include? m }
        def fetch_multi(*names)
          raise ArgumentError, "Missing block: `Cache#fetch_multi` requires a block." \
            unless block_given?

          options = names.extract_options!
          options = merged_options(options)

          instrument :read_multi, names, options do |payload|
            read_multi_entries(names, options).tap do |results|
              payload[:hits] = results.keys
              payload[:super_operation] = :fetch_multi

              writes = {}

              (names - results.keys).each do |name|
                results[name] = writes[name] = yield(name)
              end

              write_multi writes, options
            end
          end
        end

        def read_multi(*names)
          options = names.extract_options!
          options = merged_options(options)

          instrument :read_multi, names, options do |payload|
            read_multi_entries(names, options).tap do |results|
              payload[:hits] = results.keys
            end
          end
        end

        def write_multi(hash, options = nil)
          options = merged_options(options)

          instrument :write_multi, hash, options do |payload|
            entries = hash.each_with_object({}) do |(name, value), memo|
              memo[normalize_key(name, options)] = \
                Entry.new(value, options.merge(version: normalize_version(name, options)))
            end

            write_multi_entries entries, options
          end
        end
      end

      protected

      def make_entry(value)
        case value
        when ActiveSupport::Cache::Entry, nil
          value
        else
          ActiveSupport::Cache::Entry.new(value)
        end
      end

      def read_entry(key, options)
        make_entry(@store.load(key, moneta_options(options)))
      end

      def write_entry(key, entry, options)
        value = options[:raw] ? entry.value.to_s : entry
        @store.store(key, value, moneta_options(options))
        true
      end

      def delete_entry(key, options)
        @store.delete(key, moneta_options(options))
        true
      end

      def read_multi_entries(names, options)
        keys = names.map { |name| normalize_key(name, options) }
        entries = @store.
          values_at(*keys, **moneta_options(options)).
          map(&method(:make_entry))

        names.zip(keys, entries).map do |name, key, entry|
          next if entry.nil?
          delete_entry(key, options) if entry.expired?
          next if entry.expired? || entry.mismatched?(normalize_version(name, options))

          [name, entry.value]
        end.compact.to_h
      end

      def write_multi_entries(hash, options)
        pairs = if options[:raw]
                  hash.transform_values { |entry| entry.value.to_s }
                else
                  hash
                end

        @store.merge!(pairs, moneta_options(options))
        hash
      end

      private

      def moneta_options(options)
        new_options = options ? options.dup : {}
        new_options[:expires] = new_options.delete(:expires_in).to_r if new_options.include?(:expires_in)
        new_options
      end
    end
  end
end
