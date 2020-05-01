require_relative './helper.rb'

describe 'standard_sequel', adapter: :Sequel do
  include_context :sequel

  moneta_store(:Sequel) { postgres_options.merge(table: "standard_sequel") }
  moneta_specs STANDARD_SPECS.with_each_key
end
