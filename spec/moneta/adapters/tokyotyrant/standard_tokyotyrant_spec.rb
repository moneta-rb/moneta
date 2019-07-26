describe 'standard_tokyotyrant', adapter: :TokyoTyrant do
  start_tokyotyrant(10655)
  moneta_store :TokyoTyrant, port: 10655
  moneta_specs STANDARD_SPECS
end
