# -*- coding: utf-8 -*-
require 'minitest/autorun'
require 'juno'
require 'fileutils'

module Helper
  def make_tempdir
    tmp = File.join(File.dirname(__FILE__), 'tmp')
    FileUtils.mkpath(tmp)
    tmp
  end
end

module Juno
  TYPES = {
    'String' => ['key', 'key2'],
    'Object' => [{:foo => :bar}, {:bar => :baz}]
  }

  NullSpecification = proc do
    include Helper

    before do
      @store = new_store
      @store.clear
    end

    after do
      @store.close.must_equal nil if @store
    end

    TYPES.each do |type, (key, key2)|
      it "reads from keys that are #{type}s like a Hash" do
        @store[key].must_equal nil
      end

      it "guarantees that the same String value is returned when setting a #{type} key" do
        value = 'value'
        (@store[key] = value).must_be_same_as value
      end

      it "guarantees that the same Object value is returned when setting a #{type} key" do
        value = {:foo => :bar}
        (@store[key] = value).must_be_same_as value
      end

      it "returns false from key? if a #{type} key is not available" do
        @store.key?(key).must_equal false
      end

      it "returns nil from delete if an element for a #{type} key does not exist" do
        @store.delete(key).must_equal nil
      end

      it "removes all #{type} keys from the store with clear" do
        @store[key] = 'value'
        @store[key2] = 'value2'
        @store.clear.must_equal nil
        @store.key?(key).wont_equal true
        @store.key?(key2).wont_equal true
      end

      it "fetches a #{type} key with a default value with fetch, if the key is not available" do
        @store.fetch(key, 'value').must_equal 'value'
      end

      it "fetches a #{type} key with a block with fetch, if the key is not available" do
        @store.fetch(key) { |k| 'value' }.must_equal 'value'
      end

      it 'must accept options' do
        @store.key?(key, :foo => 42).must_equal false
        @store.fetch(key, nil, :foo => 42).must_equal nil
        @store.delete(key, :foo => 42).must_equal nil
        @store.clear(:foo => 42).must_equal nil
        @store.store(key, 'value', :foo => 42).must_equal 'value'
      end
    end
  end

  Specification = proc do
    class_eval(&NullSpecification)

    TYPES.each do |type, (key, key2)|
      it "writes String values to keys that are #{type}s like a Hash" do
        @store[key] = 'value'
        @store[key].must_equal 'value'
      end

      it "writes Object values to keys that are #{type}s like a Hash" do
        value = {:foo => :bar}
        @store[key] = value
        @store[key].must_equal(:foo => :bar)
      end

      it "guarantees that a different String value is retrieved from the #{type} key" do
        value = 'value'
        @store[key] = value
        @store[key].wont_be_same_as(value)
      end

      it "guarantees that a different Object value is retrieved from the #{type} key" do
        value = {:foo => :bar}
        @store[key] = value
        @store[key].wont_be_same_as(:foo => :bar)
      end

      it "returns true from key? if a #{type} key is available" do
        @store[key] = 'value'
        @store.key?(key).must_equal true
      end

      it "removes and returns an element with a #{type} key from the backing store via delete if it exists" do
        @store[key] = 'value'
        @store.delete(key).must_equal 'value'
        @store.key?(key).must_equal false
      end

      it "does not run the block if the #{type} key is available" do
        @store[key] = 'value'
        unaltered = "unaltered"
        @store.fetch(key) { unaltered = "altered" }
        unaltered.must_equal "unaltered"
      end

      it "fetches a #{type} key with a default value with fetch, if the key is available" do
        @store[key] = 'value2'
        @store.fetch(key, 'value').must_equal 'value2'
      end

      it "stores #{key} values with #store" do
        @store.store(key, 'value').must_equal 'value'
        @store[key].must_equal 'value'
      end
    end

    def marshal_error
      # HACK: Marshalling structs in rubinius without class name throws
      # NoMethodError (to_sym). TODO: Create an issue for rubinius!
      RUBY_ENGINE == 'rbx' ? NoMethodError : TypeError
    end

    it "refuses to #[] from keys that cannot be marshalled" do
      lambda do
        @store[Struct.new(:foo).new(:bar)]
      end.must_raise(marshal_error)
    end

    it "refuses to fetch from keys that cannot be marshalled" do
      lambda do
        @store.fetch(Struct.new(:foo).new(:bar), true)
      end.must_raise(marshal_error)
    end

    it "refuses to #[]= to keys that cannot be marshalled" do
      lambda do
        @store[Struct.new(:foo).new(:bar)] = 'value'
      end.must_raise(marshal_error)
    end

    it "refuses to store to keys that cannot be marshalled" do
      lambda do
        @store.store Struct.new(:foo).new(:bar), 'value'
      end.must_raise(marshal_error)
    end

    it "refuses to check for key? if the key cannot be marshalled" do
      lambda do
        @store.key? Struct.new(:foo).new(:bar)
      end.must_raise(marshal_error)
    end

    it "refuses to delete a key if the key cannot be marshalled" do
      lambda do
        @store.delete Struct.new(:foo).new(:bar)
      end.must_raise(marshal_error)
    end
  end

  ExpiresSpecification = proc do
    class_eval(&Specification)

    it 'should support expires on store' do
      @store.store('key', 'value', :expires => 2)
      @store['key'].must_equal 'value'
      sleep 3
      @store['key'].must_equal nil
    end

    it 'should support updating the expiration time in fetch' do
      @store.store('key2', 'value2', :expires => 2)
      @store['key2'].must_equal 'value2'
      sleep 1
      @store.fetch('key2', nil, :expires => 3).must_equal 'value2'
      sleep 1
      @store['key2'].must_equal 'value2'
      sleep 3
      @store['key2'].must_equal nil
    end

    it 'should respect expires in delete' do
      @store.store('key', 'value', :expires => 2)
    @store['key'].must_equal 'value'
    sleep 3
    @store.delete('key').must_equal nil
  end
end
end
