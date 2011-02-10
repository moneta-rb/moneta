# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'moneta/version'

Gem::Specification.new do |s|
  s.name = 'dkastner-moneta'
  s.version = Moneta::VERSION
  s.authors = ['Yehuda Katz', 'Derek Kastner']
  s.email = %w{wycats@gmail.com dkastner@gmail.com}
  s.date = '2011-02-10'
  s.description = %q{A unified interface to key/value stores}
  s.extra_rdoc_files = %w{README LICENSE TODO}
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.homepage = 'http://github.com/dkastner/moneta'
  s.require_paths = ["lib"]
  s.summary = %q{A unified interface to key/value stores, including MongoDB, Redis, Tokyo, and ActiveRecord}

  s.add_development_dependency 'bundler'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'

  # Adapter-specific requirements:
  if ENV['ACTIVERECORD']
    s.add_development_dependency 'activerecord' 
    s.add_development_dependency 'sqlite3-ruby' 
  end

  s.add_development_dependency 'couchrest' if ENV['COUCH']
  
  if ENV['DM']
    s.add_development_dependency 'datamapper'
    s.add_development_dependency 'dm-core'
    s.add_development_dependency 'dm-migrations'
  end

  s.add_development_dependency 'fog' if ENV['FOG']

  if ENV['MEMCACHE']
    s.add_development_dependency 'localmemcache' 
    s.add_development_dependency 'memcache-client'
  end

  s.add_development_dependency 'mongo' if ENV['MONGO']

  s.add_development_dependency 'redis' if ENV['REDIS']

  if ENV['TOKYO']
    s.add_development_dependency 'tokyocabinet'
    s.add_development_dependency 'tokyotyrant'
  end

  s.add_development_dependency 'xattr' if ENV['XATTR']
end
