require 'pathname'

module Moneta
  module Adapters
    # Filesystem backend
    # @api public
    class File
      include Defaults
      include Config

      supports :create, :increment, :each_key

      config :dir, required: true do |dir:, **_|
        ::Pathname.new(dir).expand_path
      end

      # @param [Hash] options
      # @option options [String] :dir Directory where files will be stored
      def initialize(options = {})
        configure(**options)
        config.dir.mkpath
        raise "#{config.dir} is not a directory" unless config.dir.directory?
      end

      # (see Proxy#key?)
      def key?(key, options = {})
        store_path(key).file?
      end

      # (see Proxy#each_key)
      def each_key(&block)
        return enum_for(:each_key) unless block_given?

        config.dir.find do |pathname|
          yield pathname.relative_path_from(config.dir).to_path unless pathname.directory?
        end

        self
      end

      # (see Proxy#load)
      def load(key, options = {})
        store_path(key).read(mode: 'rb')
      rescue Errno::ENOENT
        nil
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        temp_file = config.dir.join("value-#{Process.pid}-#{Thread.current.object_id}")
        path = store_path(key)
        path.dirname.mkpath
        temp_file.write(value, mode: 'wb')
        temp_file.rename(path.to_path)
        value
      rescue
        temp_file.unlink rescue nil
        raise
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        temp_file = config.dir.join("value-#{Process.pid}-#{Thread.current.object_id}")
        path = store_path(key)
        path.rename(temp_file.to_path)

        temp_file.read.tap do
          temp_file.unlink
          path.ascend.lazy.drop(1).each do |path|
            break if (path <=> config.dir) <= 0
            path.unlink
          rescue
            break
          end
        end
      rescue Errno::ENOENT
        nil
      end

      # (see Proxy#clear)
      def clear(options = {})
        temp_dir = Pathname.new("#{config.dir}-#{Process.pid}-#{Thread.current.object_id}")
        config.dir.rename(temp_dir.to_path)
        config.dir.mkpath
        self
      rescue Errno::ENOENT
        self
      ensure
        temp_dir.rmtree
      end

      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
        path = store_path(key)
        path.dirname.mkpath
        path.open(::File::RDWR | ::File::CREAT) do |f|
          Thread.pass until f.flock(::File::LOCK_EX | ::File::LOCK_NB)
          content = f.read
          amount += Integer(content) unless content.empty?
          content = amount.to_s
          f.binmode
          f.pos = 0
          f.write(content)
          f.truncate(content.bytesize)
          amount
        end
      end

      # (see Proxy#create)
      def create(key, value, options = {})
        path = store_path(key)
        path.dirname.mkpath
        path.open(::File::WRONLY | ::File::CREAT | ::File::EXCL) do |f|
          f.binmode
          f.write(value)
        end
        true
      rescue Errno::EEXIST
        false
      end

      protected

      def store_path(key)
        config.dir.join(key).cleanpath.expand_path.tap do |pathname|
          raise "not a descendent" unless pathname.ascend.lazy.drop(1).include?(config.dir)
        end
      end
    end
  end
end
