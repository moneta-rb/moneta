describe 'standard_yaml_with_expires' do
  moneta_store :YAML do
    {file: File.join(tempdir, "simple_yaml_with_expires"), expires: true}
  end

  moneta_loader{ |value| value }

  moneta_specs STANDARD_SPECS.without_marshallable_value.with_expires.without_concurrent
end
