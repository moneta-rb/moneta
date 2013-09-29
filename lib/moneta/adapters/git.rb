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
        @branch[key]
        true
      rescue ::MultiGit::Error::InvalidTraversal
        false
      end

      # (see Proxy#load)
      def load(key, options = {})
        object = @branch[key]
        object == :file ? object.content : nil
      rescue ::MultiGit::Error::InvalidTraversal
        nil
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        @branch.commit do |builder|
          builder.tree[key] = value
        end
        value
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        object = @branch[key]
        value = object.type == :file ? object.content : nil
        @branch.commit do |builder|
          builder.tree.delete(key)
        end
        value
      rescue ::MultiGit::Error::InvalidTraversal
        nil
      end

      # (see Proxy#clear)
      def clear(options = {})
        @branch.resolve.update(:pessimistic) do
          ::MultiGit::Commit::Builder.new
        end
        self
      end

      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
        @branch.commit do |builder|
          begin
            content = builder.tree[key].content
            amount += Utils.to_int(content) unless content.empty?
          rescue ::MultiGit::Error::InvalidTraversal
          end
          builder.tree[key] = amount.to_s
        end
        amount
      end

      # (see Proxy#create)
      def create(key, value, options = {})
        @branch.commit do |builder|
          builder.tree[key] = value
        end
        true
      end
    end
  end
end
