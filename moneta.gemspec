# -*- encoding: utf-8 -*-
require File.dirname(__FILE__) + '/lib/moneta/version'
require 'date'

Gem::Specification.new do |s|
  s.name             = 'moneta'
  s.version          = Moneta::VERSION
  s.date             = Date.today.to_s
  s.authors          = ['Daniel Mendler', 'Yehuda Katz', 'Hannes Georg']
  s.email            = %w{mail@daniel-mendler.de wycats@gmail.com hannes.georg@googlemail.com}
  s.description      = 'A unified interface to key/value stores'
  s.extra_rdoc_files = %w{README.md SPEC.md LICENSE}
  s.files            = `git ls-files`.split("\n")
  s.test_files       = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables      = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.homepage         = 'http://github.com/minad/moneta'
  s.licenses         = %w(MIT)
  s.require_paths    = %w(lib)
  s.summary          = %{A unified interface to key/value stores, including Redis, Memcached, TokyoCabinet, ActiveRecord and many more}
end
