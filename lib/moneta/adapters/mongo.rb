module Moneta
  module Adapters
    begin
      require 'moneta/adapters/mongo/official'
      Mongo = MongoOfficial
    rescue LoadError
      require 'moneta/adapters/mongo/moped'
      Mongo = MongoMoped
    end
  end
end
