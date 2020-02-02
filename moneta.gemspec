# -*- encoding: utf-8 -*-
require File.dirname(__FILE__) + '/lib/moneta/version'
require 'date'

Gem::Specification.new do |s|
  s.name             = 'moneta'
  s.version          = Moneta::VERSION
  s.date             = Date.today.to_s
  s.authors          = ['Daniel Mendler', 'Yehuda Katz', 'Hannes Georg', 'Alastair Pharo']
  s.email            = %w{mail@daniel-mendler.de wycats@gmail.com hannes.georg@googlemail.com asppsa@gmail.com}
  s.description      = 'A unified interface to key/value stores'
  s.extra_rdoc_files = %w{README.md SPEC.md LICENSE}
  s.files            = `git ls-files`.split("\n")
  s.test_files       = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables      = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.homepage         = 'https://github.com/moneta-rb/moneta'
  s.licenses         = %w(MIT)
  s.require_paths    = %w(lib)
  s.summary          = %{A unified interface to key/value stores, including Redis, Memcached, TokyoCabinet, ActiveRecord and many more}

  s.metadata = {
    'bug_tracker_uri'   => 'https://github.com/moneta-rb/moneta/issues',
    'changelog_uri'     => "https://github.com/moneta-rb/moneta/blob/v#{s.version}/CHANGES",
    'documentation_uri' => "https://www.rubydoc.info/gems/moneta/#{s.version}",
    'source_code_uri'   => "https://github.com/moneta-rb/moneta/tree/v#{s.version}",
  }

  s.required_ruby_version = '>= 2.3.0'

  s.add_development_dependency 'rspec', '~> 3.0'
  s.add_development_dependency 'rspec-retry', '~> 0.6.1'
  s.add_development_dependency 'rantly', '~> 1.2.0'
  s.add_development_dependency 'parallel_tests', '~> 2.29.2'
  s.add_development_dependency 'timecop', '~> 0.9.1'
  s.add_development_dependency 'rubocop', '~> 0.67.2'
  s.add_development_dependency 'irb', '~> 1.0.0'
end
