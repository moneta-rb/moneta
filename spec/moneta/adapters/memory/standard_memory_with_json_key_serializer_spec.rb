describe 'standard_memory_with_json_key_serializer', adapter: :Memory do
  moneta_store :Memory, {key_serializer: :json}
  moneta_specs STANDARD_SPECS.without_marshallable_key.simplekeys_only.without_persist
end
