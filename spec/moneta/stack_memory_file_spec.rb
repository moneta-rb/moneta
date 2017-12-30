describe "stack_memory_file" do
  moneta_build do
    tempdir = self.tempdir
    Moneta.build do
      use(:Stack) do
        add { adapter :Memory }
        add { adapter :File, dir: File.join(tempdir, "stack_memory_file") }
      end
    end
  end

  moneta_specs ADAPTER_SPECS.returnsame
end
