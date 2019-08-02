RSpec.shared_context :faraday_adapter do
  before :context do
    require 'faraday/adapter/manticore' if defined?(JRUBY_VERSION)
  end

  let(:faraday_adapter) do
    defined?(JRUBY_VERSION) ? :manticore : :net_http
  end
end
