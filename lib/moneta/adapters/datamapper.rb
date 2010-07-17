begin
  gem "dm-core", "~> 1.0.0"
  gem "dm-migrations", "~> 1.0.0"
  gem "dm-sqlite-adapter", "~> 1.0.0"
  require "dm-core"
  require "dm-migrations"
rescue LoadError
  puts "You need the dm-core gem in order to use the DataMapper moneta store"
  exit
end

class MonetaHash
  include DataMapper::Resource

  property :the_key, String, :key => true
  property :value, Object, :lazy => false

  def self.value(key)
    obj = self.get(key)
    obj && obj.value
  end
end

module Moneta
  module Adapters
    class DataMapper
      include Moneta::Defaults

      def initialize(options = {})
        @repository = options.delete(:repository) || :moneta
        ::DataMapper.setup(@repository, options[:setup])
        MonetaHash.auto_upgrade!(@repository)
        @hash = MonetaHash
      end

      def key?(key, *)
        repository_context { !!@hash.get(key_for(key)) }
      end

      def [](key)
        repository_context { @hash.value(key_for(key)) }
      end

      def store(key, value, *)
        string_key = key_for(key)
        repository_context {
          obj = @hash.get(string_key)
          if obj
            obj.update(string_key, value)
          else
            @hash.create(:the_key => string_key, :value => value)
          end
        }
      end

      def delete(key, *)
        string_key = key_for(key)

        repository_context {
          value = self[key]
          @hash.all(:the_key => string_key).destroy!
          value
        }
      end

      def clear(*)
        repository_context { @hash.all.destroy! }
      end

    private
      def repository_context
        repository(@repository) { yield }
      end
    end
  end
end
