describe "standard_client_unix", isolate: true, adapter: :Client do
  before :all do
    start_server Moneta::Adapters::Memory.new,
                 socket: File.join(tempdir, 'standard_client_unix')
  end

  moneta_store :Client do
    {socket: File.join(tempdir, 'standard_client_unix')}
  end

  moneta_specs STANDARD_SPECS
end
