require_relative "./lib/moneta/version"

Gem::Specification.new do |s|
  s.name             = "moneta"
  s.version          = Moneta::VERSION
  s.authors          = ["Daniel Mendler", "Yehuda Katz", "Hannes Georg", "Alastair Pharo"]
  s.email            = %w{mail@daniel-mendler.de wycats@gmail.com hannes.georg@googlemail.com me@asph.dev}
  s.description      = "A unified interface to key/value stores"
  s.extra_rdoc_files = %w{README.md SPEC.md LICENSE}
  s.files            = File.read("#{__dir__}/FILES").lines.map(&:chomp)
  s.homepage         = "https://github.com/moneta-rb/moneta"
  s.licenses         = %w(MIT)
  s.require_paths    = %w(lib)
  s.summary          = %{A unified interface to key/value stores, including Redis, Memcached, TokyoCabinet, ActiveRecord and many more}

  s.metadata = {
    "bug_tracker_uri" => "https://github.com/moneta-rb/moneta/issues",
    "changelog_uri" => "https://github.com/moneta-rb/moneta/blob/v#{s.version}/CHANGES",
    "documentation_uri" => "https://www.rubydoc.info/gems/moneta/#{s.version}",
    "source_code_uri" => "https://github.com/moneta-rb/moneta/tree/v#{s.version}",
"rubygems_mfa_required" => "true"
  }

  s.required_ruby_version = ">= 2.6.0"

  s.add_development_dependency "multi_json", "~> 1.15.0"
  s.add_development_dependency "parallel_tests", "~> 2.29.2"
  s.add_development_dependency "rantly", "~> 1.2.0"
  s.add_development_dependency "rspec", "~> 3.0"
  s.add_development_dependency "rspec-retry", "~> 0.6.1"
  s.add_development_dependency "rubocop", "~> 1.50.2"
  s.add_development_dependency "timecop", "~> 0.9.1"
end
