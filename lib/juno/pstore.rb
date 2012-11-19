require 'pstore'

module Juno
  class PStore < Base
    def initialize(options = {})
      raise 'No option :file specified' unless options[:file]
      FileUtils.mkpath(::File.dirname(options[:file]))
      @store = new_store(options)
    end

    def key?(key, options = {})
      @store.transaction(true) { @store.root?(key_for(key)) }
    end

    def load(key, options = {})
      @store.transaction(true) { @store[key_for(key)] }
    end

    def delete(key, options = {})
      @store.transaction { @store.delete(key_for(key)) }
    end

    def store(key, value, options = {})
      @store.transaction { @store[key_for(key)] = value }
    end

    def clear(options = {})
      @store.transaction do
        @store.roots.each do |key|
          @store.delete(key)
        end
      end
      nil
    end

    protected

    if RUBY_VERSION > '1.9'
      def new_store(options)
        # Create a thread-safe pstore by default
        ::PStore.new(options[:file], options.include?(:thread_safe) ? options[:thread_safe] : true)
      end
    else
      def new_store(options)
        ::PStore.new(options[:file])
      end
    end
  end
end
