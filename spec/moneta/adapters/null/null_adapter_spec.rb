describe "null_adapter", adapter: :Null do
  moneta_build do
    Moneta::Adapters::Null.new
  end

  moneta_specs MonetaSpecs.new(specs: [:null, :not_increment, :not_create, :not_persist, :not_each_key])
end
