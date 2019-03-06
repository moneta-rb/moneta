describe "standard_couch", isolate: true, adapter: :Couch do
  moneta_store :Couch, db: 'standard_couch'

  moneta_loader do |value|
    ::Marshal.load(value.unpack('m').first)
  end

  moneta_specs STANDARD_SPECS.without_increment
end
