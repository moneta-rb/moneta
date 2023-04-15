describe 'standard_daybreak', broken: ::Gem::Version.new(RUBY_VERSION) >= ::Gem::Version.new('3.2.0'), adapter: :Daybreak do
  moneta_store :Daybreak do
    {file: File.join(tempdir, "simple_daybreak")}
  end

  moneta_specs STANDARD_SPECS.without_multiprocess
end
