module Moneta
  module Adapters
    class ActiveRecord
      # @api private
      module V5ConnectionPool
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

      # @api private
      module V5
        def self.included(base)
          base.extend V5ConnectionPool
        end

        protected

        def connection_pool
          self.class.retrieve_or_establish_connection_pool(@spec)
        end

        def establish_connection_pool_from_backend
          @spec = backend.connection_pool.spec
        end

        # Feed the connection info into ActiveRecord and get back a name to use
        # for getting the connection pool
        def establish_connection_pool_from_connection(connection)
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
            else
              ::ActiveRecord::Base.connection_pool.spec.name.to_s
            end
        end
      end
    end
  end
end
