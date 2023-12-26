describe 'standard_lruhash_with_expires', adapter: :LRUHash do
  let(:t_res) { 0.125 }
  let(:min_ttl) { t_res }
  use_timecop

  moneta_store :LRUHash, {expires: true}
  moneta_specs STANDARD_SPECS.with_expires.without_persist
end
