#!/usr/bin/env ruby
# Inspired by https://coderwall.com/p/x8exja

def cmd(s)
  puts s
  system(s)
end

def cmd!(s)
  cmd(s) || abort("#{s} failed")
end

if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'rbx'
  ruby = 'rbx'
elsif defined?(JRUBY_VERSION)
  ruby = 'jruby'
else
  ruby = 'mri'
end

BUNDLE_FILE = "bundle-#{RUBY_VERSION}-#{ruby}.tar.gz"

if cmd("wget -nv -O #{BUNDLE_FILE} http://s3.amazonaws.com/minad-moneta/#{BUNDLE_FILE}")
  cmd! 'rm -rf .bundle'
  cmd! "tar -xf #{BUNDLE_FILE}"
  cmd! "rm -f #{BUNDLE_FILE}"
else
  cmd! 'bundle install --path .bundle'
  cmd! "tar -czf #{BUNDLE_FILE} .bundle"
end
