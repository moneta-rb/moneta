require 'sequel'

module Juno
  class Sequel < Base
    def initialize(options = {})
      raise 'No option :db specified' unless db = options.delete(:db)
      @table = options.delete(:table) || :juno
      @db = ::Sequel.connect(db, options)
      @db.create_table?(@table) do
        primary_key :k
        String :k
        String :v
      end
    end

    def key?(key, options = {})
      !!sequel_table[:k => key_for(key)]
    end

    def load(key, options = {})
      result = sequel_table[:k => key_for(key)]
      result ? deserialize(result[:v]) : nil
    end

    def store(key, value, options = {})
      sequel_table.insert(:k => key_for(key), :v => serialize(value))
      value
    end

    def delete(key, options = {})
      if value = self[key]
        sequel_table.filter(:k => key_for(key)).delete
        value
      end
    end

    def clear(options = {})
      sequel_table.delete
      nil
    end

    private

    def serialize(value)
      [super].pack('m').strip
    end

    def deserialize(value)
      super(value.unpack('m').first)
    end

    def key_for(key)
      [super].pack('m').strip
    end

    def sequel_table
      @sequel_table ||= @db[@table]
    end
  end
end
