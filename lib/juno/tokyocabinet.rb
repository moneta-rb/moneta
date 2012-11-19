require 'tokyocabinet'

module Juno
  class TokyoCabinet < Memory
    def initialize(options = {})
      file = options[:file]
      raise 'No option :file specified' unless options[:file]
      @store = ::TokyoCabinet::HDB.new
      unless @store.open(file, ::TokyoCabinet::HDB::OWRITER | ::TokyoCabinet::HDB::OCREAT)
        raise @store.errmsg(@store.ecode)
      end
    end

    def key?(key, options = {})
      !!load(key, options)
    end

    def delete(key, options = {})
      value = load(key, options)
      if value
        @store.delete(key_for(key))
        value
      end
    end

    def close
      @store.close
      nil
    end
  end
end
