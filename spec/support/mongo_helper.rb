# frozen_string_literal: true

module MongoHelper
  def mongo_config(opts = {})
    prefix = ENV.fetch('TEST_ENV_NUMBER', '')
    opts.merge(collection: "#{prefix}#{opts[:collection]}")
  end

  def self.mongo_config(args)
    Class.include(MongoHelper).new.mongo_config(args)
  end
end