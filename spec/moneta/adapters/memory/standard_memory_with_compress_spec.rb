describe 'standard_memory_with_compress', adapter: :Memory do
  moneta_store :Memory, {compress: true}

  moneta_loader do |value|
    Marshal.load(::Zlib::Inflate.inflate(value))
  end

  moneta_specs STANDARD_SPECS.without_persist
end
