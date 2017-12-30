describe "stack_file_memory" do
  moneta_build do
    tempdir = self.tempdir
    Moneta.build do
      use(:Stack) do
        add(Moneta.new(:Null))
        add(Moneta::Adapters::Null.new)
        add { adapter :File, dir: File.join(tempdir, "stack_file_memory") }
        add { adapter :Memory }
      end
    end
  end

  moneta_specs ADAPTER_SPECS.without_increment.without_create
end
