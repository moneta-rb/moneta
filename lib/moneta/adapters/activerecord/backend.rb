require 'uri'

module Moneta
  module Adapters
    class ActiveRecord
      # @api private
      class Backend
        @connection_lock = ::Mutex.new

        class << self
          attr_reader :connection_lock
        end

        attr_reader :table_name
        delegate :connection_handler, to: ::ActiveRecord::Base

        def initialize(table:, connection: nil, **options)
          @table_name = table
          @connection = connection
          if connection
            @owner_name =
              case connection
              when Symbol, String
                connection.to_s
              when Hash
                hash = connection.reject { |key| [:username, 'username', :password, 'password'].member?(key) }
                'moneta?' + URI.encode_www_form(hash.to_a.sort)
              when nil
                nil
              else
                raise "Unexpected connection: #{connection}"
              end
          end
        end

        def connection_pool
          if @connection
            connection_handler.retrieve_connection_pool(@owner_name) ||
              self.class.connection_lock.synchronize do
                connection_handler.retrieve_connection_pool(@owner_name) ||
                  connection_handler.establish_connection(@connection, owner_name: @owner_name)
              end
          else
            ::ActiveRecord::Base.connection_pool
          end
        end
      end
    end
  end
end
