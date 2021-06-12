RSpec.shared_context :start_server do |**options|
  before :context do
    begin
      options.each do |key, value|
        options[key] = instance_exec(&value) if value.respond_to? :call
      end
      backend = options.delete(:backend)
      @server = Moneta::Server.new(backend, options)
      @thread = Thread.new { @server.run }
      sleep 0.1 until @server.running?
    rescue Exception => ex
      puts "Failed to start server - #{ex.message}"
      tries ||= 0
      tries += 1
      timeout = options[:timeout] || Moneta::Server.config_defaults[:timeout]
      sleep 1
      tries < 3 ? retry : raise
    end
  end

  after :context do
    @server&.stop
    @thread&.join
  end
end
