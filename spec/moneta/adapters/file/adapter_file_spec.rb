describe 'adapter_file', adapter: :File do
  moneta_build do
    Moneta::Adapters::File.new(dir: File.join(tempdir, "adapter_file"))
  end

  moneta_specs ADAPTER_SPECS.with_each_key
end
