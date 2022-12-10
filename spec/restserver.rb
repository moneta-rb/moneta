require 'faraday'
require 'rack'
require 'rack/moneta_rest'
require 'webrick'

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
    :server => :webrick,
    :Port => port,
    :AccessLog => [],
    :Logger => WEBrick::Log.new($stderr, WEBrick::BasicLog::ERROR)
  )

  Thread.start { server.start }

  begin
    Faraday.get("http://127.0.0.1:#{port}")
  rescue Faraday::ConnectionFailed, Errno::EBADF
    tries ||= 5
    tries -= 1
    if tries > 0
      sleep 0.1
      retry
    else
      raise
    end
  end

  server
end

def stop_restserver(server)
  server.server.shutdown
end

