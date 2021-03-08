require_relative './helper.rb'

describe 'standard_sequel_with_expires', adapter: :Sequel, postgres: true do
  include_context :sequel

  let(:t_res) { 0.125 }
  let(:min_ttl) { t_res }
  use_timecop

  moneta_store :Sequel do
    postgres_options.merge(
      table: "standard_sequel_with_expires",
      expires: true
    )
  end

  moneta_specs STANDARD_SPECS.with_expires.with_each_key
end
