describe "pool" do
  moneta_build do
    tempdir = self.tempdir
    Moneta.build do
      use :Pool do
        adapter :Daybreak, file: File.join(tempdir, "pool")
      end
    end
  end

  moneta_specs ADAPTER_SPECS.returnsame.with_each_key
end
