require 'uri'

module Moneta
  module Adapters
    class ActiveRecord
      # @api private
      class V5Backend
        @connection_lock = ::Mutex.new

        class << self
          attr_reader :connection_lock
          delegate :configurations, :configurations=, :connection_handler, to: ::ActiveRecord::Base

          def retrieve_connection_pool(spec_name)
            connection_handler.retrieve_connection_pool(spec_name.to_s)
          end

          def establish_connection(spec_name)
            connection_lock.synchronize do
              if connection_pool = retrieve_connection_pool(spec_name)
                connection_pool
              else
                connection_handler.establish_connection(spec_name.to_sym)
              end
            end
          end

          def retrieve_or_establish_connection_pool(spec_name)
            retrieve_connection_pool(spec_name) || establish_connection(spec_name)
          end
        end

        attr_reader :table_name

        def initialize(table:, connection: nil, **options)
          @table_name = table
          @spec =
            case connection
            when Symbol
              connection
            when Hash, String
              # Normalize the connection specification to a hash
              resolver = ::ActiveRecord::ConnectionAdapters::ConnectionSpecification::Resolver.new \
                'dummy' => connection

              # Turn the config into a standardised hash, sans a couple of bits
              hash = resolver.resolve(:dummy)
              hash.delete('name')
              hash.delete(:username) # For security
              hash.delete(:password) # For security
              # Make a name unique to this config
              name = 'moneta?' + URI.encode_www_form(hash.to_a.sort)
              # Add into configurations unless its already there (initially done without locking for
              # speed)
              unless self.class.configurations.key? name
                self.class.connection_lock.synchronize do
                  self.class.configurations[name] = connection \
                    unless self.class.configurations.key? name
                end
              end

              name.to_sym
            when nil
              nil
            else
              raise "Unexpected connection: #{connection}"
            end
        end

        def connection_pool
          if @spec
            self.class.retrieve_or_establish_connection_pool(@spec)
          else
            ::ActiveRecord::Base.connection_pool
          end
        end
      end
    end
  end
end
