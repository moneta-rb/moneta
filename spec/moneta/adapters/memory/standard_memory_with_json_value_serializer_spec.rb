describe 'standard_memory_with_json_value_serializer', adapter: :Memory do
  moneta_store :Memory, {value_serializer: :json}

  moneta_loader do |value|
    ::MultiJson.load(value)
  end
  
  moneta_specs STANDARD_SPECS.without_marshallable_value.simplevalues_only.without_persist
end
