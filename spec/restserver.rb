require 'rack'
require 'rack/moneta_rest'

MONETA_RESTSERVER_LOGGER =
  if defined?(JRUBY_VERSION)
    require 'rjack-logback'
    RJack::Logback.config_console( :level => :off )
    require 'fishwife'
    nil
  else
    require 'webrick'
    # Keep webrick quiet
    WEBrick::Log.new($stderr, WEBrick::BasicLog::ERROR)
  end

class MonetaRestServerShutdown < StandardError; end

def start_restserver(port)
  server = Rack::Server.new(
    :app => Rack::Builder.app do
      use Rack::Lint
      map '/moneta' do
        run Rack::MonetaRest.new(:Memory)
      end
    end,
    :environment => 'none',
    :server => defined?(JRUBY_VERSION) ? :Fishwife : :webrick,
    :Port => port,
    :AccessLog => [],
    :Logger => MONETA_RESTSERVER_LOGGER
  )

  Thread.start { server.start }
  server
end

def stop_restserver(server)
  server.server.shutdown
end

