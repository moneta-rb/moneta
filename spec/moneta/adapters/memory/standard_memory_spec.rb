describe 'standard_memory', adapter: :Memory do
  moneta_store :Memory
  moneta_specs STANDARD_SPECS.without_persist

  context 'with serialize_keys_unless_string: false' do
    moneta_store :Memory, serialize_keys_unless_string: false
    include_examples :each_key
  end
end
