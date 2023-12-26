describe 'standard_memory_with_json_serializer', adapter: :Memory do
  moneta_store :Memory, {serializer: :json}

  moneta_loader do |value|
    ::MultiJson.load(value)
  end

  moneta_specs STANDARD_SPECS.without_marshallable.simplekeys_only.simplevalues_only.without_persist
end
