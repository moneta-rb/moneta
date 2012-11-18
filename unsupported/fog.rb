require 'fog'

module Juno
  class Fog < Base
    def initialize(options = {})
      bucket = options.delete(:namespace)
      cloud = options.delete(:cloud).new(options)
      @directory = cloud.directories.create(:key => bucket)
    end

    def key?(key, options = {})
      !@directory.files.head(key_for(key)).nil?
    end

    def [](key)
      if value = get(key)
        deserialize(value.body)
      end
    end

    def delete(key, options = {})
      value = get(key)
      if value
        value.destroy
        deserialize(value.body)
      end
    end

    def store(key, value, options = {})
      @directory.files.create(:key => key_for(key), :body => serialize(value))
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

  class S3 < Fog
    def initialize(options = {})
      options[:cloud] = ::Fog::AWS::S3
      super
    end
  end

  class Rackspace < Fog
    def initialize(options = {})
      options[:cloud] = ::Fog::Rackspace::Files
      super
    end
  end
end
