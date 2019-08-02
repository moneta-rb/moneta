require 'rack'
require 'webrick'
require 'rack/moneta_rest'

# Keep webrick quiet
::WEBrick::HTTPServer.class_eval do
  def access_log(config, req, res); end
end
::WEBrick::BasicLog.class_eval do
  def log(level, data); end
end

RSpec.shared_context :start_restserver do |port|
  before :context do
    @restserver_thread = Thread.start do
      Rack::Server.start(
        :app => Rack::Builder.app do
          use Rack::Lint
          map '/moneta' do
            run Rack::MonetaRest.new(:store => :Memory)
          end
        end,
        :environment => :none,
        :server => :webrick,
        :Port => port
      )
    end
  end

  after :context do
    Thread.kill(@restserver_thread)
    @restserver_thread = nil
  end
end
