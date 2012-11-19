require 'fog'

module Juno
  class Fog < Base
    def initialize(options = {})
      raise 'No option :dir specified' unless dir = options.delete(:dir)
      storage = ::Fog::Storage.new(options)
      @directory = storage.directories.create(:key => dir)
    end

    def key?(key, options = {})
      !!@directory.files.head(key_for(key))
    end

    def load(key, options = {})
      if value = get(key)
        deserialize(value.body)
      end
    end

    def delete(key, options = {})
      value = get(key)
      if value
        body = deserialize(value.body)
        value.destroy
        body
      end
    end

    def store(key, value, options = {})
      @directory.files.create(:key => key_for(key), :body => serialize(value))
      value
    end

    def clear(options = {})
      @directory.files.all.each do |file|
        file.destroy
      end
      nil
    end

    private

    def get(key)
      @directory.files.get(key_for(key))
    end
  end
end
