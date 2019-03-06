describe "pool", proxy: :Pool do
  moneta_build do
    tempdir = self.tempdir
    Moneta.build do
      use :Pool do
        adapter :File, dir: File.join(tempdir, "pool")
      end
    end
  end

  moneta_specs ADAPTER_SPECS.with_each_key
end
