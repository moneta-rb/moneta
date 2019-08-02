require_relative '../../../restserver.rb'

RSpec.shared_context :start_restserver do |port|
  before :context do
    @restserver_handle = start_restserver(port)
  end

  after :context do
    stop_restserver(@restserver_handle)
    @restserver_handle = nil
  end
end
