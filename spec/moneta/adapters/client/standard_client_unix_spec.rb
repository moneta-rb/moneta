require_relative './client_helper.rb'

describe "standard_client_unix", adapter: :Client do
  include_context :start_server,
                  backend: ->{ Moneta::Adapters::Memory.new },
                  socket: ->{ File.join(tempdir, 'standard_client_unix') }

  moneta_store :Client do
    { socket: File.join(tempdir, 'standard_client_unix') }
  end

  moneta_specs STANDARD_SPECS.with_each_key

  it 'supports multiple clients' do
    store['shared_key'] = 'shared_val'
    threads = (1..32).map do |i|
      Thread.new do
        client = new_store
        (1..31).each do |j|
          client['shared_key'].should == 'shared_val'
          client["key-\#{j}-\#{i}"] = "val-\#{j}-\#{i}"
          client["key-\#{j}-\#{i}"].should == "val-\#{j}-\#{i}"
        end
      end
    end
    threads.map(&:join)
  end
end
