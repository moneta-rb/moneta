describe 'adapter_yaml', adapter: :YAML do
  moneta_build do
    Moneta::Adapters::YAML.new(file: File.join(tempdir, "adapter_yaml"))
  end

  moneta_specs STANDARD_SPECS.simplevalues_only.simplekeys_only.with_each_key.without_transform.without_concurrent
end
