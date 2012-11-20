# -*- encoding: utf-8 -*-
require File.dirname(__FILE__) + '/lib/juno/version'
require 'date'

Gem::Specification.new do |s|
  s.name = 'juno'
  s.version = Juno::VERSION
  s.date = Date.today.to_s
  s.authors = ['Yehuda Katz', 'Derek Kastner', 'Daniel Mendler']
  s.email = %w{wycats@gmail.com dkastner@gmail.com mail@daniel-mendler.de}
  s.description = 'A unified interface to key/value stores (moneta replacement)'
  s.extra_rdoc_files = %w{README.md SPEC.md LICENSE}
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.homepage = 'http://github.com/minad/juno'
  s.require_paths = ['lib']
  s.summary = %{A unified interface to key/value stores, including MongoDB, Redis, Tokyo, and ActiveRecord}
end
