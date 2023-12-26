describe 'standard_yaml', adapter: :YAML do
  moneta_store :YAML do
    {file: File.join(tempdir, "simple_yaml")}
  end

  moneta_loader{ |value| value }

  moneta_specs STANDARD_SPECS.without_marshallable_value.without_concurrent
end
