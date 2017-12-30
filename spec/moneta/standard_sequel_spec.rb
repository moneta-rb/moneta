describe 'standard_sequel' do
  moneta_store :Sequel, {db: if defined?(JRUBY_VERSION)
                                   "jdbc:mysql://localhost/moneta?user=root"
                                 else
                                   "mysql2://root:@localhost/moneta"
                                 end,
                             table: "simple_sequel"}

  moneta_specs STANDARD_SPECS
end
