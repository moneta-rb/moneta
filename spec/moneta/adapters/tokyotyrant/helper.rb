RSpec.shared_context :start_tokyotyrant do |port|
  before :context do
    @tokyotyrant = spawn("ttserver -port #{port} -le -log #{tempdir}/tokyotyrant#{port}.log #{tempdir}/tokyotyrant#{port}.tch")
    sleep 0.5
  end

  after :context do
    Process.kill("TERM", @tokyotyrant)
    Process.wait(@tokyotyrant)
    @tokyotyrant = nil
  end
end
