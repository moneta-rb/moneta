require 'helper'

describe Juno::Cache do
  def new_store
    Juno::Cache.new(Juno::Redis.new, Juno::Memory.new)
  end

  class_eval(&Juno::Specification)

  it 'should store loaded values in cache' do
    @store.backend['foo'] = 42
    @store.cache['foo'].must_equal nil
    @store['foo'].must_equal 42
    @store.cache['foo'].must_equal 42
    @store.backend.delete('foo')
    @store['foo'].must_equal 42
    @store.delete('foo')
    @store['foo'].must_equal nil
  end
end
