require 'helper'

begin
  describe Juno::TokyoCabinet do
    def new_store
      Juno::TokyoCabinet.new(:file => File.join(make_tempdir, 'tokyocabinet.db'))
    end

    class_eval(&Juno::Specification)
  end
rescue LoadError => ex
  puts "Juno::TokyoCabinet not tested: #{ex.message}"
end
