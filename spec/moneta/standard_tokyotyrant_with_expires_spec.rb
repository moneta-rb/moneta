describe 'standard_tokyotyrant_with_expires' do
  moneta_store :TokyoTyrant, {expires: true}
  moneta_specs STANDARD_SPECS.with_expires
end
