require 'yaml/store'

module Juno
  class YAML < Juno::PStore
    def new_store(options)
      ::YAML::Store.new(options[:file])
    end
  end
end
