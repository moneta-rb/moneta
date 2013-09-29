require 'multi_git'
require 'fileutils'

module Moneta
  module Adapters
    # Git backend
    # @api public
    class Git
      include Defaults
      attr_reader :backend

      supports :create, :increment

      # @param [Hash] options
      # @option options [String] :dir Directory where files will be stored
      def initialize(options = {})
        raise ArgumentError, 'Option :dir is required' unless dir = options[:dir]
        FileUtils.mkpath(dir)
        @backend = ::MultiGit.open(dir, :init => true)
        @branch = @backend.branch(options[:branch] || 'master')
      end

      # (see Proxy#key?)
      def key?(key, options = {})
        @branch.target.tree.key?(key)
      end

      # (see Proxy#load)
      def load(key, options = {})
        object = @branch[key]
        object.type == :file ? object.content : nil
      rescue ::MultiGit::Error::InvalidTraversal
        nil
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        commit do |builder|
          builder.tree[key] = value
        end
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        commit do |builder|
          if builder.tree.key?(key)
            object = builder.tree.@branch[key]
        value = object.type == :file ? object.content : nil
          builder.tree.delete(key)
        end
        value
      rescue ::MultiGit::Error::InvalidTraversal
        nil
      end

      # (see Proxy#clear)
      def clear(options = {})
        commit do |builder|
          # FIXME: Hack to create empty commit tree!
          builder.instance_variable_set(:@tree, ::MultiGit::Tree::Builder.new)
        end
        self
      end

      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
        commit do |builder|
          begin
            content = @branch[key].content
            amount += Utils.to_int(content) unless content.empty?
          rescue ::MultiGit::Error::InvalidTraversal
          end
          builder.tree[key] = amount.to_s
        end
        amount
      end

      # (see Proxy#create)
      def create(key, value, options = {})
        commit do |builder|
          if builder.tree.key?(key)
            #builder.abort
            false
          else
            builder.tree[key] = value
            true
          end
        end
      end

      private

      def commit
        # FIXME: @branch.commit returns altered reference, maybe it would be
        # more intuitive to update the reference itself!
        # This would also make the result hack unnecessary.
        result = nil
        @branch = @branch.commit(:lock => :pessimistic) do |builder|
          result = yield(builder)
        end
        result
      end
    end
  end
end
